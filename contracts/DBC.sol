// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./shared/GAATypes.sol";
import "./shared/GAAErrors.sol";
import "./shared/IGAAContracts.sol";
import "./shared/IDPAContracts.sol";

/**
 * @title DBC (Digital Bayanihan Chain)
 * @dev Orchestrator contract for GAA budget management
 *      Uses interface pattern for external contract references
 *      Includes Pausable for emergency stops
 */
contract DBC is Ownable, ReentrancyGuard, Pausable {
    // ============ State Variables ============

    /// @notice Current lifecycle phase
    GAATypes.Phase public currentPhase;

    /// @notice Current fiscal year (starts 2025, increments on each preparation)
    uint256 public fiscalYear;

    /// @notice Mapping of department code to Department contract address
    mapping(string => address) private _departments;

    /// @notice Array of department codes for enumeration
    string[] private _departmentCodes;

    /// @notice Responsible department for initiating transition to Enactment
    address public responsibleMintingDept;

    /// @notice Responsible department for initiating transition to Finality
    address public responsibleEnactmentDept;

    /// @notice Mapping of fiscal year to AgencyBudgetDPA address
    mapping(uint256 => address) public agencyBudgetDPA;

    /// @notice Mapping of fiscal year to SPFDPA address
    mapping(uint256 => address) public spfDPA;

    /// @notice Mapping of fiscal year to BESFDPA address
    mapping(uint256 => address) public besfDPA;

    // ============ Events ============

    /// @notice Emitted when phase changes
    event PhaseChanged(
        GAATypes.Phase indexed oldPhase,
        GAATypes.Phase indexed newPhase
    );

    /// @notice Emitted when fiscal year increments
    event FiscalYearIncremented(
        uint256 indexed oldYear,
        uint256 indexed newYear
    );

    /// @notice Emitted when a department is registered
    event DepartmentRegistered(
        string indexed codeHash,
        string code,
        address department
    );

    /// @notice Emitted when a department is removed
    event DepartmentRemoved(string indexed codeHash, string code);

    /// @notice Emitted when responsible departments are set
    event ResponsibleDepartmentsSet(address mintingDept, address enactmentDept);

    /// @notice Emitted when a DPA contract is registered
    event DPARegistered(
        string indexed dpaType,
        uint256 indexed fiscalYear,
        address dpaAddress
    );

    /// @notice Emitted when agency expenditure is submitted
    event AgencyExpenditureSubmitted(
        uint256 indexed tokenId,
        address indexed agency,
        GAATypes.ExpenseType expenseType,
        uint256 amount
    );

    /// @notice Emitted when SPF expenditure is submitted
    event SPFExpenditureSubmitted(
        uint256 indexed tokenId,
        address indexed submitter,
        GAATypes.ExpenseType expenseType,
        uint256 amount
    );

    /// @notice Emitted when BESF expenditure is submitted
    /// @dev Content structure is flexible - no specific fields emitted
    event BESFExpenditureSubmitted(
        uint256 indexed tokenId,
        address indexed submitter
    );

    // ============ Modifiers ============

    /// @dev Only allow during Preparation phase
    modifier onlyPreparation() {
        if (currentPhase != GAATypes.Phase.Preparation) {
            revert GAAErrors.InvalidPhase();
        }
        _;
    }

    /// @dev Only allow during Minting phase
    modifier onlyMinting() {
        if (currentPhase != GAATypes.Phase.Minting) {
            revert GAAErrors.InvalidPhase();
        }
        _;
    }

    /// @dev Only allow during Preparation or Minting phase
    modifier onlyPreparationOrMinting() {
        if (
            currentPhase != GAATypes.Phase.Preparation &&
            currentPhase != GAATypes.Phase.Minting
        ) {
            revert GAAErrors.InvalidPhase();
        }
        _;
    }

    /// @dev Only allow the responsible minting department
    modifier onlyResponsibleMinting() {
        if (msg.sender != responsibleMintingDept) {
            revert GAAErrors.NotResponsibleDepartment();
        }
        _;
    }

    /// @dev Only allow the responsible enactment department
    modifier onlyResponsibleEnactment() {
        if (msg.sender != responsibleEnactmentDept) {
            revert GAAErrors.NotResponsibleDepartment();
        }
        _;
    }

    // ============ Constructor ============

    /**
     * @dev Initializes DBC in Preparation phase at fiscal year 2026
     *      (starts at 2025, increments immediately since Preparation)
     */
    constructor() Ownable(msg.sender) {
        currentPhase = GAATypes.Phase.Preparation;
        fiscalYear = 2025;
        _incrementFiscalYear();
    }

    // ============ Pausable Functions ============

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ============ Phase Transition Functions ============

    function transitionToMinting()
        external
        onlyOwner
        onlyPreparation
        whenNotPaused
    {
        GAATypes.Phase oldPhase = currentPhase;
        currentPhase = GAATypes.Phase.Minting;
        emit PhaseChanged(oldPhase, currentPhase);
    }

    function transitionToEnactment()
        external
        onlyResponsibleMinting
        onlyMinting
        whenNotPaused
    {
        GAATypes.Phase oldPhase = currentPhase;
        currentPhase = GAATypes.Phase.Enactment;
        emit PhaseChanged(oldPhase, currentPhase);
    }

    function transitionToFinality()
        external
        onlyResponsibleEnactment
        whenNotPaused
    {
        if (currentPhase != GAATypes.Phase.Enactment) {
            revert GAAErrors.InvalidPhaseTransition();
        }
        GAATypes.Phase oldPhase = currentPhase;
        currentPhase = GAATypes.Phase.Finality;
        emit PhaseChanged(oldPhase, currentPhase);
    }

    function completeAndReset()
        external
        onlyResponsibleEnactment
        whenNotPaused
    {
        if (currentPhase != GAATypes.Phase.Finality) {
            revert GAAErrors.InvalidPhaseTransition();
        }
        GAATypes.Phase oldPhase = currentPhase;
        currentPhase = GAATypes.Phase.Preparation;
        emit PhaseChanged(oldPhase, currentPhase);
        _incrementFiscalYear();
    }

    // ============ Department Registration ============

    /**
     * @notice Register a pre-deployed department contract
     * @param departmentCode Unique department code
     * @param departmentAddress Pre-deployed Department contract address
     */
    function registerDepartment(
        string calldata departmentCode,
        address departmentAddress
    ) external onlyOwner onlyPreparation whenNotPaused {
        if (bytes(departmentCode).length == 0) revert GAAErrors.EmptyString();
        if (departmentAddress == address(0)) revert GAAErrors.InvalidAddress();
        if (_departments[departmentCode] != address(0))
            revert GAAErrors.DepartmentAlreadyExists();

        // Verify it's a valid Department contract by checking its code
        string memory deptCode = IDepartment(departmentAddress).code();
        if (keccak256(bytes(deptCode)) != keccak256(bytes(departmentCode))) {
            revert GAAErrors.InvalidAddress();
        }

        _departments[departmentCode] = departmentAddress;
        _departmentCodes.push(departmentCode);

        emit DepartmentRegistered(
            departmentCode,
            departmentCode,
            departmentAddress
        );
    }

    /**
     * @notice Remove a department
     */
    function removeDepartment(
        string calldata departmentCode
    ) external onlyOwner onlyPreparation whenNotPaused {
        if (_departments[departmentCode] == address(0))
            revert GAAErrors.DepartmentNotFound();

        address deptAddress = _departments[departmentCode];
        if (
            deptAddress == responsibleMintingDept ||
            deptAddress == responsibleEnactmentDept
        ) {
            revert GAAErrors.Unauthorized();
        }

        delete _departments[departmentCode];

        for (uint256 i = 0; i < _departmentCodes.length; i++) {
            if (
                keccak256(bytes(_departmentCodes[i])) ==
                keccak256(bytes(departmentCode))
            ) {
                _departmentCodes[i] = _departmentCodes[
                    _departmentCodes.length - 1
                ];
                _departmentCodes.pop();
                break;
            }
        }

        emit DepartmentRemoved(departmentCode, departmentCode);
    }

    /**
     * @notice Set responsible departments for phase transitions
     */
    function setResponsibleDepartments(
        address mintingDept,
        address enactmentDept
    ) external onlyOwner onlyPreparation whenNotPaused {
        if (mintingDept == address(0) || enactmentDept == address(0)) {
            revert GAAErrors.InvalidAddress();
        }

        bool mintingFound = false;
        bool enactmentFound = false;
        for (uint256 i = 0; i < _departmentCodes.length; i++) {
            if (_departments[_departmentCodes[i]] == mintingDept)
                mintingFound = true;
            if (_departments[_departmentCodes[i]] == enactmentDept)
                enactmentFound = true;
        }
        if (!mintingFound || !enactmentFound)
            revert GAAErrors.DepartmentNotFound();

        responsibleMintingDept = mintingDept;
        responsibleEnactmentDept = enactmentDept;

        emit ResponsibleDepartmentsSet(mintingDept, enactmentDept);
    }

    // ============ DPA Registration ============

    /**
     * @notice Register AgencyBudgetDPA for current fiscal year
     * @param dpaAddress Pre-deployed AgencyBudgetDPA contract address
     */
    function registerAgencyBudgetDPA(
        address dpaAddress
    ) external onlyOwner onlyPreparationOrMinting whenNotPaused {
        if (agencyBudgetDPA[fiscalYear] != address(0))
            revert GAAErrors.DPAAlreadyDeployed();
        if (dpaAddress == address(0)) revert GAAErrors.InvalidAddress();

        // Verify orchestrator is this contract
        if (IAgencyBudgetDPA(dpaAddress).orchestrator() != address(this)) {
            revert GAAErrors.InvalidAddress();
        }

        agencyBudgetDPA[fiscalYear] = dpaAddress;
        emit DPARegistered("AgencyBudget", fiscalYear, dpaAddress);
    }

    /**
     * @notice Register SPFDPA for current fiscal year
     */
    function registerSPFDPA(
        address dpaAddress
    ) external onlyOwner onlyPreparationOrMinting whenNotPaused {
        if (spfDPA[fiscalYear] != address(0))
            revert GAAErrors.DPAAlreadyDeployed();
        if (dpaAddress == address(0)) revert GAAErrors.InvalidAddress();

        if (ISPFDPA(dpaAddress).orchestrator() != address(this)) {
            revert GAAErrors.InvalidAddress();
        }

        spfDPA[fiscalYear] = dpaAddress;
        emit DPARegistered("SPF", fiscalYear, dpaAddress);
    }

    /**
     * @notice Register BESFDPA for current fiscal year
     */
    function registerBESFDPA(
        address dpaAddress
    ) external onlyOwner onlyPreparationOrMinting whenNotPaused {
        if (besfDPA[fiscalYear] != address(0))
            revert GAAErrors.DPAAlreadyDeployed();
        if (dpaAddress == address(0)) revert GAAErrors.InvalidAddress();

        if (IBESFDPA(dpaAddress).orchestrator() != address(this)) {
            revert GAAErrors.InvalidAddress();
        }

        besfDPA[fiscalYear] = dpaAddress;
        emit DPARegistered("BESF", fiscalYear, dpaAddress);
    }

    // ============ Agency Expenditure Functions ============

    function submitAgencyExpenditure(
        address agency,
        GAATypes.ExpenseType expenseType,
        uint256 amount,
        string calldata pdfSource,
        uint256 pageSource,
        string calldata uri
    )
        external
        onlyMinting
        nonReentrant
        whenNotPaused
        returns (uint256 tokenId)
    {
        if (msg.sender != agency) revert GAAErrors.Unauthorized();

        address dpaAddress = agencyBudgetDPA[fiscalYear];
        if (dpaAddress == address(0)) revert GAAErrors.DPANotDeployed();

        IAgency agencyContract = IAgency(agency);
        string memory agencyCode = agencyContract.code();
        string memory agencyName = agencyContract.name();
        string memory deptCode = agencyContract.getDepartmentCode();
        string memory deptName = agencyContract.getDepartmentName();

        address deptAddress = _departments[deptCode];
        if (deptAddress == address(0)) revert GAAErrors.DepartmentNotFound();
        if (!IDepartment(deptAddress).isAgency(agency))
            revert GAAErrors.AgencyNotInDepartment();

        bytes memory content = IAgencyBudgetDPA(dpaAddress).encodeContent(
            expenseType,
            amount,
            pdfSource,
            pageSource,
            deptCode,
            deptName,
            agencyCode,
            agencyName
        );

        tokenId = IAgencyBudgetDPA(dpaAddress).mint(agency, uri, content);
        emit AgencyExpenditureSubmitted(tokenId, agency, expenseType, amount);
    }

    function reviseAgencyExpenditure(
        address agency,
        uint256 tokenId,
        GAATypes.ExpenseType expenseType,
        uint256 amount,
        string calldata pdfSource,
        uint256 pageSource,
        string calldata uri,
        string calldata reason
    )
        external
        onlyMinting
        nonReentrant
        whenNotPaused
        returns (uint256 newTokenId)
    {
        if (msg.sender != agency) revert GAAErrors.Unauthorized();

        address dpaAddress = agencyBudgetDPA[fiscalYear];
        if (dpaAddress == address(0)) revert GAAErrors.DPANotDeployed();

        IAgencyBudgetDPA dpa = IAgencyBudgetDPA(dpaAddress);
        if (dpa.ownerOf(tokenId) != agency) revert GAAErrors.NotTokenOwner();

        IAgency agencyContract = IAgency(agency);
        bytes memory content = dpa.encodeContent(
            expenseType,
            amount,
            pdfSource,
            pageSource,
            agencyContract.getDepartmentCode(),
            agencyContract.getDepartmentName(),
            agencyContract.code(),
            agencyContract.name()
        );

        newTokenId = dpa.revise(tokenId, uri, content, reason);
    }

    // ============ SPF Expenditure Functions ============

    function submitSPFExpenditure(
        GAATypes.SPFInput calldata input
    )
        external
        onlyResponsibleMinting
        onlyMinting
        nonReentrant
        whenNotPaused
        returns (uint256 tokenId)
    {
        address dpaAddress = spfDPA[fiscalYear];
        if (dpaAddress == address(0)) revert GAAErrors.DPANotDeployed();

        GAATypes.SPFContent memory content = GAATypes.SPFContent({
            expenseType: input.expenseType,
            amount: input.amount,
            pdfSource: input.pdfSource,
            pageSource: input.pageSource,
            fundingSourceCode: input.fundingSourceCode,
            spfCategoryName: input.spfCategoryName,
            supervisingDepartmentName: input.supervisingDepartmentName,
            supervisingDepartmentCode: input.supervisingDepartmentCode,
            recipientCode: input.recipientCode,
            recipientName: input.recipientName
        });

        bytes memory encodedContent = abi.encode(content);
        tokenId = ISPFDPA(dpaAddress).mint(
            msg.sender,
            input.uri,
            encodedContent
        );
        emit SPFExpenditureSubmitted(
            tokenId,
            msg.sender,
            input.expenseType,
            input.amount
        );
    }

    function reviseSPFExpenditure(
        GAATypes.SPFRevisionInput calldata input
    )
        external
        onlyResponsibleMinting
        onlyMinting
        nonReentrant
        whenNotPaused
        returns (uint256 newTokenId)
    {
        address dpaAddress = spfDPA[fiscalYear];
        if (dpaAddress == address(0)) revert GAAErrors.DPANotDeployed();

        ISPFDPA dpa = ISPFDPA(dpaAddress);
        if (dpa.ownerOf(input.tokenId) != msg.sender)
            revert GAAErrors.NotTokenOwner();

        GAATypes.SPFContent memory content = GAATypes.SPFContent({
            expenseType: input.expenseType,
            amount: input.amount,
            pdfSource: input.pdfSource,
            pageSource: input.pageSource,
            fundingSourceCode: input.fundingSourceCode,
            spfCategoryName: input.spfCategoryName,
            supervisingDepartmentName: input.supervisingDepartmentName,
            supervisingDepartmentCode: input.supervisingDepartmentCode,
            recipientCode: input.recipientCode,
            recipientName: input.recipientName
        });

        bytes memory encodedContent = abi.encode(content);
        newTokenId = dpa.revise(
            input.tokenId,
            input.uri,
            encodedContent,
            input.reason
        );
    }

    // ============ BESF Expenditure Functions ============
    // Note: BESF uses raw bytes for content to allow flexible content structure.
    // The content encoding is handled by the caller and BESF DPA.

    function submitBESFExpenditure(
        string calldata uri,
        bytes calldata content
    )
        external
        onlyResponsibleMinting
        onlyMinting
        nonReentrant
        whenNotPaused
        returns (uint256 tokenId)
    {
        address dpaAddress = besfDPA[fiscalYear];
        if (dpaAddress == address(0)) revert GAAErrors.DPANotDeployed();

        tokenId = IBESFDPA(dpaAddress).mint(msg.sender, uri, content);
        emit BESFExpenditureSubmitted(tokenId, msg.sender);
    }

    function reviseBESFExpenditure(
        uint256 tokenId,
        string calldata uri,
        bytes calldata content,
        string calldata reason
    )
        external
        onlyResponsibleMinting
        onlyMinting
        nonReentrant
        whenNotPaused
        returns (uint256 newTokenId)
    {
        address dpaAddress = besfDPA[fiscalYear];
        if (dpaAddress == address(0)) revert GAAErrors.DPANotDeployed();

        IBESFDPA dpa = IBESFDPA(dpaAddress);
        if (dpa.ownerOf(tokenId) != msg.sender)
            revert GAAErrors.NotTokenOwner();

        newTokenId = dpa.revise(tokenId, uri, content, reason);
    }

    // ============ View Functions ============

    function getDepartment(
        string calldata departmentCode
    ) external view returns (address) {
        return _departments[departmentCode];
    }

    function getAllDepartmentCodes() external view returns (string[] memory) {
        return _departmentCodes;
    }

    function getDepartmentCount() external view returns (uint256) {
        return _departmentCodes.length;
    }

    function isDepartment(address deptAddress) external view returns (bool) {
        for (uint256 i = 0; i < _departmentCodes.length; i++) {
            if (_departments[_departmentCodes[i]] == deptAddress) {
                return true;
            }
        }
        return false;
    }

    function getCurrentDPAs()
        external
        view
        returns (address agency, address spf, address besf)
    {
        return (
            agencyBudgetDPA[fiscalYear],
            spfDPA[fiscalYear],
            besfDPA[fiscalYear]
        );
    }

    // ============ Internal Functions ============

    function _incrementFiscalYear() internal {
        uint256 oldYear = fiscalYear;
        fiscalYear++;
        emit FiscalYearIncremented(oldYear, fiscalYear);
    }
}
