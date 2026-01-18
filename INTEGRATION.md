# GAA Contracts - Integration Guide

This guide explains how developers can **read budget data** and **listen for events** from the GAA smart contracts on Polygon.

## Contract Addresses (Amoy Testnet)

| Contract | Address |
|----------|---------|
| DBC (Orchestrator) | `0x...` |
| AgencyBudgetDPA | `0x...` |
| SPFDPA | `0x...` |

> **Note:** Replace with actual deployed addresses from your sync-state.json

---

## Reading On-Chain Data

### 1. Setup (ethers.js v6)

```javascript
import { ethers } from 'ethers';

// Connect to Polygon Amoy
const provider = new ethers.JsonRpcProvider('https://rpc-amoy.polygon.technology');

// Contract ABIs (simplified - get full ABIs from artifacts)
const AGENCY_BUDGET_DPA_ABI = [
  'function totalSupply() view returns (uint256)',
  'function tokenURI(uint256 tokenId) view returns (string)',
  'function getAgencyBudgetContent(uint256 tokenId) view returns (tuple(uint8 expenseType, uint256 amount, string pdfSource, uint256 pageSource, string departmentCode, string departmentName, string agencyCode, string agencyName))',
  'function ownerOf(uint256 tokenId) view returns (address)',
  'event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)'
];

const SPF_DPA_ABI = [
  'function totalSupply() view returns (uint256)',
  'function tokenURI(uint256 tokenId) view returns (string)',
  'function getSPFContent(uint256 tokenId) view returns (tuple(uint8 expenseType, uint256 amount, string pdfSource, uint256 pageSource, string fundingSourceCode, string spfCategoryName, string supervisingDepartmentName, string supervisingDepartmentCode, string recipientCode, string recipientName))',
  'event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)'
];

const DBC_ABI = [
  'function currentPhase() view returns (uint8)',
  'function fiscalYear() view returns (uint256)',
  'function getDepartment(string code) view returns (address)',
  'function getDepartmentCount() view returns (uint256)',
  'event PhaseChanged(uint8 indexed oldPhase, uint8 indexed newPhase)',
  'event AgencyExpenditureSubmitted(uint256 indexed tokenId, address indexed agency, uint8 expenseType, uint256 amount)',
  'event SPFExpenditureSubmitted(uint256 indexed tokenId, address indexed submitter, uint8 expenseType, uint256 amount)'
];
```

### 2. Reading Agency Budget Data

```javascript
// Contract addresses (from sync-state.json)
const AGENCY_BUDGET_DPA_ADDRESS = '0x...';

const agencyBudgetDPA = new ethers.Contract(
  AGENCY_BUDGET_DPA_ADDRESS,
  AGENCY_BUDGET_DPA_ABI,
  provider
);

// Get total minted tokens
const totalSupply = await agencyBudgetDPA.totalSupply();
console.log('Total budget tokens:', totalSupply.toString());

// Get budget content for a specific token
const tokenId = 1;
const content = await agencyBudgetDPA.getAgencyBudgetContent(tokenId);

console.log({
  expenseType: ['PersonnelServices', 'MOOE', 'CapitalOutlays', 'FinancialExpenses'][content.expenseType],
  amount: ethers.formatUnits(content.amount, 0), // Amount in PHP (no decimals)
  pdfSource: content.pdfSource,
  pageSource: content.pageSource.toString(),
  departmentCode: content.departmentCode,
  departmentName: content.departmentName,
  agencyCode: content.agencyCode,
  agencyName: content.agencyName,
});

// Get token metadata URI (points to IPFS JSON)
const tokenURI = await agencyBudgetDPA.tokenURI(tokenId);
console.log('Metadata URI:', tokenURI);
```

### 3. Reading SPF Data

```javascript
const SPF_DPA_ADDRESS = '0x...';

const spfDPA = new ethers.Contract(SPF_DPA_ADDRESS, SPF_DPA_ABI, provider);

// Get SPF content
const spfContent = await spfDPA.getSPFContent(1);

console.log({
  expenseType: ['PersonnelServices', 'MOOE', 'CapitalOutlays', 'FinancialExpenses'][spfContent.expenseType],
  amount: ethers.formatUnits(spfContent.amount, 0),
  spfCategoryName: spfContent.spfCategoryName,
  fundingSourceCode: spfContent.fundingSourceCode,
  supervisingDepartmentName: spfContent.supervisingDepartmentName,
  recipientName: spfContent.recipientName,
});
```

### 4. Reading DBC State

```javascript
const DBC_ADDRESS = '0x...';
const dbc = new ethers.Contract(DBC_ADDRESS, DBC_ABI, provider);

// Get current phase
const phase = await dbc.currentPhase();
const phases = ['Preparation', 'Minting', 'Enactment', 'Finality'];
console.log('Current Phase:', phases[phase]);

// Get fiscal year
const fiscalYear = await dbc.fiscalYear();
console.log('Fiscal Year:', fiscalYear.toString());

// Get department count
const deptCount = await dbc.getDepartmentCount();
console.log('Registered Departments:', deptCount.toString());
```

---

## Listening for Events

### 1. Real-time Budget Submissions

```javascript
// Listen for new agency budget tokens being minted
agencyBudgetDPA.on('Transfer', async (from, to, tokenId) => {
  // Only new mints (from zero address)
  if (from === ethers.ZeroAddress) {
    console.log(`New budget token minted: #${tokenId}`);
    
    // Fetch the content
    const content = await agencyBudgetDPA.getAgencyBudgetContent(tokenId);
    console.log(`  Department: ${content.departmentName}`);
    console.log(`  Agency: ${content.agencyName}`);
    console.log(`  Amount: ₱${content.amount.toLocaleString()}`);
  }
});
```

### 2. Listen for Phase Changes

```javascript
const dbc = new ethers.Contract(DBC_ADDRESS, DBC_ABI, provider);

dbc.on('PhaseChanged', (oldPhase, newPhase) => {
  const phases = ['Preparation', 'Minting', 'Enactment', 'Finality'];
  console.log(`Phase changed: ${phases[oldPhase]} → ${phases[newPhase]}`);
});
```

### 3. Listen for Agency Expenditure Submissions

```javascript
dbc.on('AgencyExpenditureSubmitted', (tokenId, agency, expenseType, amount) => {
  const types = ['PersonnelServices', 'MOOE', 'CapitalOutlays', 'FinancialExpenses'];
  console.log(`New expenditure submitted:`);
  console.log(`  Token ID: ${tokenId}`);
  console.log(`  Agency: ${agency}`);
  console.log(`  Type: ${types[expenseType]}`);
  console.log(`  Amount: ₱${amount.toLocaleString()}`);
});

dbc.on('SPFExpenditureSubmitted', (tokenId, submitter, expenseType, amount) => {
  console.log(`New SPF submitted: Token #${tokenId}, Amount: ₱${amount}`);
});
```

### 4. Query Historical Events

```javascript
// Get all budget submissions from a specific block range
const filter = dbc.filters.AgencyExpenditureSubmitted();
const events = await dbc.queryFilter(filter, -10000); // Last 10k blocks

for (const event of events) {
  console.log({
    tokenId: event.args.tokenId.toString(),
    agency: event.args.agency,
    amount: event.args.amount.toString(),
    blockNumber: event.blockNumber,
    txHash: event.transactionHash,
  });
}
```

---

## Fetching IPFS Metadata

Each token has a metadata JSON on IPFS with full budget details:

```javascript
const tokenURI = await agencyBudgetDPA.tokenURI(tokenId);
// Returns: "https://emerald-certain-muskox-778.mypinata.cloud/ipfs/Qm..."

const response = await fetch(tokenURI);
const metadata = await response.json();

console.log(metadata);
/*
{
  "name": "Department of Agriculture - Bureau of Fisheries - Personnel Services",
  "description": "Personnel Services for Department of Agriculture amounting to ₱1,234,567,890",
  "image": "https://emerald-certain-muskox-778.mypinata.cloud/ipfs/Qm...",
  "attributes": [
    { "trait_type": "Type", "value": "Departmental Budget" },
    { "trait_type": "Department Code", "value": "01" },
    { "trait_type": "Amount", "value": 1234567890 },
    ...
  ]
}
*/
```

---

## Expense Type Mapping

| Code | Enum | Description |
|------|------|-------------|
| 0 | PersonnelServices | Salaries, wages, allowances |
| 1 | MOOE | Maintenance and Other Operating Expenses |
| 2 | CapitalOutlays | Land, buildings, equipment |
| 3 | FinancialExpenses | Interest, bank charges |

---

## Full Example: Budget Dashboard

```javascript
import { ethers } from 'ethers';

async function getBudgetDashboard() {
  const provider = new ethers.JsonRpcProvider('https://rpc-amoy.polygon.technology');
  
  const agencyBudgetDPA = new ethers.Contract(
    '0x...', // AgencyBudgetDPA address
    AGENCY_BUDGET_DPA_ABI,
    provider
  );
  
  const totalTokens = await agencyBudgetDPA.totalSupply();
  
  let totalBudget = 0n;
  const byDepartment = {};
  
  for (let i = 1; i <= totalTokens; i++) {
    const content = await agencyBudgetDPA.getAgencyBudgetContent(i);
    totalBudget += content.amount;
    
    if (!byDepartment[content.departmentCode]) {
      byDepartment[content.departmentCode] = {
        name: content.departmentName,
        total: 0n,
        agencies: new Set(),
      };
    }
    byDepartment[content.departmentCode].total += content.amount;
    byDepartment[content.departmentCode].agencies.add(content.agencyCode);
  }
  
  console.log('=== GAA Budget Dashboard ===');
  console.log(`Total Budget: ₱${totalBudget.toLocaleString()}`);
  console.log(`Total Tokens: ${totalTokens}`);
  console.log('\nBy Department:');
  
  for (const [code, data] of Object.entries(byDepartment)) {
    console.log(`  ${data.name}: ₱${data.total.toLocaleString()} (${data.agencies.size} agencies)`);
  }
}

getBudgetDashboard();
```

---

## Resources

- **Polygon Amoy Explorer:** https://amoy.polygonscan.com
- **IPFS Gateway:** https://emerald-certain-muskox-778.mypinata.cloud/ipfs/
- **DPA Framework:** https://www.npmjs.com/package/@dpa-oss/dpa

## License

MIT
