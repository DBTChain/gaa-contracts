# GAA Contracts

Smart contracts for the **General Appropriations Act (GAA)** budget management system on the Digital Bayanihan Chain.

Built on the [`@dpa-oss/dpa`](https://www.npmjs.com/package/@dpa-oss/dpa) framework for Digital Public Assets.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        DBC (Orchestrator)                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                 │
│  │ Phase Mgmt  │  │ Fiscal Year │  │  Pausable   │                 │
│  └─────────────┘  └─────────────┘  └─────────────┘                 │
│                                                                     │
│  registerDepartment()    registerAgencyBudgetDPA()                  │
│  setResponsibleDepts()   registerSPFDPA()                           │
│  transitionToMinting()   registerBESFDPA()                          │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
         ┌─────────────────────┼─────────────────────┐
         │                     │                     │
         ▼                     ▼                     ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   Department    │  │ AgencyBudgetDPA │  │     SPFDPA      │
│  ┌───────────┐  │  │   (ERC721A)     │  │   (ERC721A)     │
│  │  Agency   │  │  │                 │  │                 │
│  │  Agency   │  │  │  Budget tokens  │  │  SPF tokens     │
│  └───────────┘  │  │  per agency     │  │  per fund       │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

## Lifecycle Phases

```
┌───────────────┐      ┌───────────────┐      ┌───────────────┐      ┌───────────────┐
│  PREPARATION  │ ───► │    MINTING    │ ───► │   ENACTMENT   │ ───► │   FINALITY    │
│   (Phase 0)   │      │   (Phase 1)   │      │   (Phase 2)   │      │   (Phase 3)   │
└───────────────┘      └───────────────┘      └───────────────┘      └───────────────┘
       │                      │                      │                      │
       │ • Register depts     │ • Mint tokens        │ • Locked state       │ • Archive
       │ • Register DPAs      │ • Submit budgets     │ • No changes         │ • Reset to Prep
       │ • Set responsible    │ • Revise entries     │                      │ • Increment FY
       └──────────────────────┴──────────────────────┴──────────────────────┘
```

## Contracts

| Contract | Description |
|----------|-------------|
| `DBC.sol` | Orchestrator - manages phases, departments, and DPA registration |
| `Department.sol` | Government department with agency management |
| `Agency.sol` | Government agency that submits expenditures |
| `AgencyBudgetDPA.sol` | ERC721A tokens for agency budget line items |
| `SPFDPA.sol` | ERC721A tokens for Special Purpose Funds |
| `BESFDPA.sol` | ERC721A tokens for BESF (placeholder) |

## Data Structures

### Agency Budget Content
```solidity
struct AgencyBudgetContent {
    ExpenseType expenseType;    // PersonnelServices(1), MOOE(2), CapitalOutlays(3), FinancialExpenses(6)
    uint256 amount;
    string pdfSource;
    uint256 pageSource;
    string departmentCode;      // Auto-populated
    string departmentName;      // Auto-populated
    string agencyCode;          // Auto-populated
    string agencyName;          // Auto-populated
}
```

### SPF Content
```solidity
struct SPFContent {
    ExpenseType expenseType;
    uint256 amount;
    string pdfSource;
    uint256 pageSource;
    string fundingSourceCode;
    string spfCategoryName;
    string supervisingDepartmentName;
    string supervisingDepartmentCode;
    string recipientCode;
    string recipientName;
}
```

## Quick Start

```bash
# Install dependencies
npm install

# Compile contracts
npm run compile

# Run tests
npm run test

# Deploy locally
npm run deploy:local

# Deploy to Amoy testnet
npm run deploy:amoy

# Deploy to Polygon mainnet
npm run deploy:polygon
```

## Deployment Flow

1. **Deploy DBC** - Main orchestrator
2. **Deploy DPAs** - AgencyBudgetDPA, SPFDPA, BESFDPA with DBC as orchestrator
3. **Register DPAs** - Call `registerAgencyBudgetDPA()`, etc.
4. **Deploy Departments** - With DBC address
5. **Register Departments** - Call `registerDepartment()`
6. **Set Responsible** - Call `setResponsibleDepartments()`
7. **Transition** - Call `transitionToMinting()` to begin budget submission

## Security Features

- **Pausable**: All state-changing functions can be paused by owner
- **ReentrancyGuard**: Protection against reentrancy attacks
- **Phase Enforcement**: Actions restricted to appropriate phases
- **Ownership**: Departments own agencies; agencies owned by document managers
- **Revision Tracking**: Immutable audit trail via DPA revision system

## Networks

| Network | Chain ID | Command |
|---------|----------|---------|
| Hardhat | 31337 | `npm run deploy:local` |
| Amoy | 80002 | `npm run deploy:amoy` |
| Polygon | 137 | `npm run deploy:polygon` |

## Environment Variables

```bash
PRIVATE_KEY=your_deployer_private_key
POLYGONSCAN_API_KEY=your_api_key
AMOY_RPC_URL=https://rpc-amoy.polygon.technology
POLYGON_RPC_URL=https://polygon-rpc.com
```

## License

MIT
