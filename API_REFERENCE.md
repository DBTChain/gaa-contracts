# 📚 GAA Contracts - API Reference

> A comprehensive reference guide for all functions, events, and data types in the GAA smart contract system.

---

## 📋 Table of Contents

- [DBC (Orchestrator)](#dbc-orchestrator)
- [Department](#department)
- [Agency](#agency)
- [AgencyBudgetDPA](#agencybudgetdpa)
- [SPFDPA](#spfdpa)
- [Data Types](#data-types)
- [Events Reference](#events-reference)

---

## DBC (Orchestrator)

The main orchestrator contract that manages the GAA budget lifecycle.

### State Variables

| Variable | Type | Description |
|----------|------|-------------|
| `currentPhase` | `Phase` | Current lifecycle phase (0-3) |
| `fiscalYear` | `uint256` | Current fiscal year (starts 2026) |
| `responsibleMintingDept` | `address` | Department authorized for minting transitions |
| `responsibleEnactmentDept` | `address` | Department authorized for enactment transitions |

---

### Phase Management

#### `pause()`

```solidity
function pause() external onlyOwner
```

**Description:** Pauses all state-changing operations for emergency stops.

| Access | Modifier |
|--------|----------|
| Owner only | `onlyOwner` |

---

#### `unpause()`

```solidity
function unpause() external onlyOwner
```

**Description:** Resumes operations after a pause.

| Access | Modifier |
|--------|----------|
| Owner only | `onlyOwner` |

---

#### `transitionToMinting()`

```solidity
function transitionToMinting() external onlyOwner onlyPreparation whenNotPaused
```

**Description:** Transitions from Preparation (Phase 0) to Minting (Phase 1). Enables budget token minting.

| Access | Phase Required | Emits |
|--------|---------------|-------|
| Owner only | Preparation | `PhaseChanged` |

---

#### `transitionToEnactment()`

```solidity
function transitionToEnactment() external onlyResponsibleMinting onlyMinting whenNotPaused
```

**Description:** Transitions from Minting (Phase 1) to Enactment (Phase 2). Locks budget submissions.

| Access | Phase Required | Emits |
|--------|---------------|-------|
| Responsible Minting Dept | Minting | `PhaseChanged` |

---

#### `transitionToFinality()`

```solidity
function transitionToFinality() external onlyResponsibleEnactment whenNotPaused
```

**Description:** Transitions from Enactment (Phase 2) to Finality (Phase 3).

| Access | Phase Required | Emits |
|--------|---------------|-------|
| Responsible Enactment Dept | Enactment | `PhaseChanged` |

---

#### `completeAndReset()`

```solidity
function completeAndReset() external onlyResponsibleEnactment whenNotPaused
```

**Description:** Completes the fiscal year cycle and resets to Preparation phase. Increments fiscal year.

| Access | Phase Required | Emits |
|--------|---------------|-------|
| Responsible Enactment Dept | Finality | `PhaseChanged`, `FiscalYearIncremented` |

---

### Department Registration

#### `registerDepartment()`

```solidity
function registerDepartment(
    string calldata departmentCode,
    address departmentAddress
) external onlyOwner onlyPreparation whenNotPaused
```

**Description:** Registers a pre-deployed Department contract with the orchestrator.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `departmentCode` | `string` | Unique department code (e.g., "DBM") |
| `departmentAddress` | `address` | Deployed Department contract address |

**Emits:** `DepartmentRegistered`

---

#### `removeDepartment()`

```solidity
function removeDepartment(
    string calldata departmentCode
) external onlyOwner onlyPreparation whenNotPaused
```

**Description:** Removes a department from the registry (only if not a responsible department).

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `departmentCode` | `string` | Code of department to remove |

**Emits:** `DepartmentRemoved`

---

#### `setResponsibleDepartments()`

```solidity
function setResponsibleDepartments(
    address mintingDept,
    address enactmentDept
) external onlyOwner onlyPreparation whenNotPaused
```

**Description:** Sets which departments are responsible for phase transitions.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `mintingDept` | `address` | Department for minting→enactment transition |
| `enactmentDept` | `address` | Department for enactment→finality transition |

**Emits:** `ResponsibleDepartmentsSet`

---

### DPA Registration

#### `registerAgencyBudgetDPA()`

```solidity
function registerAgencyBudgetDPA(
    address dpaAddress
) external onlyOwner onlyPreparationOrMinting whenNotPaused
```

**Description:** Registers the AgencyBudgetDPA contract for the current fiscal year.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `dpaAddress` | `address` | Deployed AgencyBudgetDPA contract |

**Emits:** `DPARegistered("AgencyBudget", fiscalYear, dpaAddress)`

---

#### `registerSPFDPA()`

```solidity
function registerSPFDPA(address dpaAddress) external
```

**Description:** Registers the SPFDPA contract for the current fiscal year.

---

#### `registerBESFDPA()`

```solidity
function registerBESFDPA(address dpaAddress) external
```

**Description:** Registers the BESFDPA contract for the current fiscal year.

---

### Expenditure Submission

#### `submitAgencyExpenditure()`

```solidity
function submitAgencyExpenditure(
    address agency,
    GAATypes.ExpenseType expenseType,
    uint256 amount,
    string calldata pdfSource,
    uint256 pageSource,
    string calldata uri
) external onlyMinting nonReentrant whenNotPaused returns (uint256 tokenId)
```

**Description:** Internal function called by Agency contracts to submit budget line items.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `agency` | `address` | Calling agency contract |
| `expenseType` | `ExpenseType` | Type of expense (0-3) |
| `amount` | `uint256` | Budget amount in PHP |
| `pdfSource` | `string` | Source PDF filename |
| `pageSource` | `uint256` | Page number in PDF |
| `uri` | `string` | IPFS metadata URI |

**Returns:** `tokenId` - The minted token ID

**Emits:** `AgencyExpenditureSubmitted`

---

#### `submitSPFExpenditure()`

```solidity
function submitSPFExpenditure(
    GAATypes.SPFInput calldata input
) external onlyResponsibleMinting onlyMinting nonReentrant whenNotPaused returns (uint256 tokenId)
```

**Description:** Submits a Special Purpose Fund expenditure (called by responsible dept).

**Emits:** `SPFExpenditureSubmitted`

---

### View Functions

#### `getDepartment()`

```solidity
function getDepartment(string calldata code) external view returns (address)
```

**Description:** Returns the address of a registered department by code.

---

#### `getDepartmentCount()`

```solidity
function getDepartmentCount() external view returns (uint256)
```

**Description:** Returns total number of registered departments.

---

#### `getAllDepartmentCodes()`

```solidity
function getAllDepartmentCodes() external view returns (string[] memory)
```

**Description:** Returns array of all registered department codes.

---

## Department

Represents a government department with agency management.

### State Variables

| Variable | Type | Description |
|----------|------|-------------|
| `code` | `string` | Department code (e.g., "01") |
| `name` | `string` | Full department name |
| `dbc` | `address` | DBC orchestrator address |
| `mainAgency` | `address` | Main/umbrella agency address |

---

### Agency Management

#### `addAgency()`

```solidity
function addAgency(
    string calldata agencyCode,
    string calldata agencyName,
    address agencyOwner
) external onlyOwner onlyPreparation returns (address agencyAddress)
```

**Description:** Creates and registers a new agency under this department.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `agencyCode` | `string` | Unique agency code |
| `agencyName` | `string` | Agency display name |
| `agencyOwner` | `address` | Owner of the new agency |

**Returns:** `agencyAddress` - Address of created Agency contract

**Emits:** `AgencyAdded`

---

#### `removeAgency()`

```solidity
function removeAgency(string calldata agencyCode) external onlyOwner onlyPreparation
```

**Description:** Removes an agency (cannot remove main agency).

**Emits:** `AgencyRemoved`

---

#### `getAgency()`

```solidity
function getAgency(string calldata agencyCode) external view returns (address)
```

**Description:** Returns agency contract address by code.

---

#### `getAllAgencyCodes()`

```solidity
function getAllAgencyCodes() external view returns (string[] memory)
```

**Description:** Returns all agency codes in this department.

---

#### `getAgencyCount()`

```solidity
function getAgencyCount() external view returns (uint256)
```

**Description:** Returns total number of agencies.

---

### SPF Functions (Responsible Department Only)

#### `submitSPFExpenditure()`

```solidity
function submitSPFExpenditure(
    GAATypes.SPFInput calldata input
) external onlyOwner returns (uint256 tokenId)
```

**Description:** Submits an SPF expenditure through the DBC. Only callable by the responsible minting department.

---

#### `transitionToEnactment()`

```solidity
function transitionToEnactment() external onlyOwner
```

**Description:** Requests phase transition to Enactment (must be responsible minting dept).

---

#### `transitionToFinality()`

```solidity
function transitionToFinality() external onlyOwner
```

**Description:** Requests phase transition to Finality (must be responsible enactment dept).

---

## Agency

Represents a government agency that submits budget expenditures.

### State Variables

| Variable | Type | Description |
|----------|------|-------------|
| `code` | `string` | Agency code |
| `name` | `string` | Agency name |
| `department` | `address` | Parent department address |
| `dbc` | `address` | DBC orchestrator address |

---

### Expenditure Functions

#### `submitExpenditure()`

```solidity
function submitExpenditure(
    GAATypes.ExpenseType expenseType,
    uint256 amount,
    string calldata pdfSource,
    uint256 pageSource,
    string calldata uri
) external onlyOwner returns (uint256 tokenId)
```

**Description:** Submits a budget line item for this agency. Mints an ERC721 token.

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `expenseType` | `ExpenseType` | Type of expense (0-3) |
| `amount` | `uint256` | Budget amount in PHP |
| `pdfSource` | `string` | Source PDF filename |
| `pageSource` | `uint256` | Page number in PDF |
| `uri` | `string` | IPFS metadata URI (CID) |

**Returns:** `tokenId` - Minted NFT token ID

---

## AgencyBudgetDPA

ERC721A token contract for agency budget line items.

### View Functions

#### `getAgencyBudgetContent()`

```solidity
function getAgencyBudgetContent(
    uint256 tokenId
) external view returns (GAATypes.AgencyBudgetContent memory content)
```

**Description:** Decodes and returns the full budget content for a token.

**Returns:** `AgencyBudgetContent` struct with all budget details.

---

#### `tokenURI()`

```solidity
function tokenURI(uint256 tokenId) public view returns (string memory)
```

**Description:** Returns the IPFS metadata URI for a token.

---

#### `totalSupply()`

```solidity
function totalSupply() public view returns (uint256)
```

**Description:** Returns total number of minted tokens.

---

## SPFDPA

ERC721A token contract for Special Purpose Funds.

### View Functions

#### `getSPFContent()`

```solidity
function getSPFContent(
    uint256 tokenId
) external view returns (GAATypes.SPFContent memory content)
```

**Description:** Decodes and returns the full SPF content for a token.

**Returns:** `SPFContent` struct with all SPF details.

---

## Data Types

### Phase Enum

```solidity
enum Phase {
    Preparation,  // 0 - Setup phase
    Minting,      // 1 - Budget submission
    Enactment,    // 2 - Locked/signed
    Finality      // 3 - Archived
}
```

---

### ExpenseType Enum

```solidity
enum ExpenseType {
    PersonnelServices,   // 0 - Code: 1
    MOOE,                // 1 - Code: 2
    CapitalOutlays,      // 2 - Code: 6
    FinancialExpenses    // 3 - Code: 3
}
```

---

### AgencyBudgetContent Struct

```solidity
struct AgencyBudgetContent {
    ExpenseType expenseType;
    uint256 amount;
    string pdfSource;
    uint256 pageSource;
    string departmentCode;
    string departmentName;
    string agencyCode;
    string agencyName;
}
```

---

### SPFContent Struct

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

---

### SPFInput Struct

```solidity
struct SPFInput {
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
    string uri;
}
```

---

## Events Reference

### DBC Events

| Event | Parameters | Description |
|-------|------------|-------------|
| `PhaseChanged` | `oldPhase`, `newPhase` | Lifecycle phase transition |
| `FiscalYearIncremented` | `oldYear`, `newYear` | New fiscal year started |
| `DepartmentRegistered` | `codeHash`, `code`, `department` | Department added |
| `DepartmentRemoved` | `codeHash`, `code` | Department removed |
| `ResponsibleDepartmentsSet` | `mintingDept`, `enactmentDept` | Responsible depts configured |
| `DPARegistered` | `dpaType`, `fiscalYear`, `dpaAddress` | DPA contract registered |
| `AgencyExpenditureSubmitted` | `tokenId`, `agency`, `expenseType`, `amount` | Budget token minted |
| `SPFExpenditureSubmitted` | `tokenId`, `submitter`, `expenseType`, `amount` | SPF token minted |

---

### Department Events

| Event | Parameters | Description |
|-------|------------|-------------|
| `AgencyAdded` | `codeHash`, `code`, `agency` | New agency created |
| `AgencyRemoved` | `codeHash`, `code` | Agency removed |

---

### DPA Events (ERC721)

| Event | Parameters | Description |
|-------|------------|-------------|
| `Transfer` | `from`, `to`, `tokenId` | Token transferred/minted |
| `TokenMinted` | `tokenId`, `to`, `cid` | New token minted |
| `TokenRevised` | `newTokenId`, `parentTokenId`, `originTokenId`, `reason` | Token revised |

---

## Error Codes

| Error | Description |
|-------|-------------|
| `InvalidPhase()` | Operation not allowed in current phase |
| `InvalidPhaseTransition()` | Invalid phase transition attempt |
| `InvalidAddress()` | Zero or invalid address provided |
| `EmptyString()` | Empty string not allowed |
| `DepartmentAlreadyExists()` | Department code already registered |
| `DepartmentNotFound()` | Department code not found |
| `AgencyAlreadyExists()` | Agency code already exists |
| `AgencyNotFound()` | Agency code not found |
| `NotResponsibleDepartment()` | Caller is not the responsible department |
| `Unauthorized()` | Caller not authorized |
| `DPAAlreadyDeployed()` | DPA already registered for fiscal year |
| `DPANotDeployed()` | Required DPA not yet deployed |

---

## License

MIT
