// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./shared/GAATypes.sol";
import "./shared/GAAErrors.sol";

// Forward declaration
interface IDepartment {
    function code() external view returns (string memory);

    function name() external view returns (string memory);

    function dbc() external view returns (address);
}

interface IDBC {
    function currentPhase() external view returns (GAATypes.Phase);

    function submitAgencyExpenditure(
        address agency,
        GAATypes.ExpenseType expenseType,
        uint256 amount,
        string calldata pdfSource,
        uint256 pageSource,
        string calldata uri
    ) external returns (uint256 tokenId);

    function reviseAgencyExpenditure(
        address agency,
        uint256 tokenId,
        GAATypes.ExpenseType expenseType,
        uint256 amount,
        string calldata pdfSource,
        uint256 pageSource,
        string calldata uri,
        string calldata reason
    ) external returns (uint256 newTokenId);
}

/**
 * @title Agency
 * @dev Agency contract representing a government agency under a department
 *      Owner is automatically the document manager with expenditure submission rights
 */
contract Agency is Ownable {
    // ============ State Variables ============

    /// @notice Agency code (e.g., "DBM-PS")
    string public code;

    /// @notice Agency name (e.g., "Procurement Service")
    string public name;

    /// @notice Reference to parent Department contract
    IDepartment public department;

    // ============ Events ============

    /// @notice Emitted when agency info is updated
    event AgencyInfoUpdated(string code, string name);

    /// @notice Emitted when expenditure is submitted
    event ExpenditureSubmitted(
        uint256 indexed tokenId,
        GAATypes.ExpenseType expenseType,
        uint256 amount
    );

    /// @notice Emitted when expenditure is revised
    event ExpenditureRevised(
        uint256 indexed oldTokenId,
        uint256 indexed newTokenId
    );

    // ============ Constructor ============

    /**
     * @param _code Agency code
     * @param _name Agency name
     * @param _department Address of parent Department contract
     * @param _owner Owner address (document manager)
     */
    constructor(
        string memory _code,
        string memory _name,
        address _department,
        address _owner
    ) Ownable(_owner) {
        if (bytes(_code).length == 0) revert GAAErrors.EmptyString();
        if (bytes(_name).length == 0) revert GAAErrors.EmptyString();
        if (_department == address(0)) revert GAAErrors.InvalidAddress();

        code = _code;
        name = _name;
        department = IDepartment(_department);
    }

    // ============ View Functions ============

    /**
     * @notice Get the DBC address through department chain
     * @return DBC contract address
     */
    function getDBC() public view returns (address) {
        return department.dbc();
    }

    /**
     * @notice Get department code
     * @return Department code string
     */
    function getDepartmentCode() external view returns (string memory) {
        return department.code();
    }

    /**
     * @notice Get department name
     * @return Department name string
     */
    function getDepartmentName() external view returns (string memory) {
        return department.name();
    }

    // ============ Expenditure Functions ============

    /**
     * @notice Submit an expenditure to the Agency Budget DPA
     * @dev Only owner (document manager) can call this
     * @param expenseType Type of expense (Personnel, MOOE, Capital, Financial)
     * @param amount Amount in smallest unit
     * @param pdfSource PDF source reference
     * @param pageSource Page number in PDF
     * @param uri Token URI for metadata
     * @return tokenId The minted token ID
     */
    function submitExpenditure(
        GAATypes.ExpenseType expenseType,
        uint256 amount,
        string calldata pdfSource,
        uint256 pageSource,
        string calldata uri
    ) external onlyOwner returns (uint256 tokenId) {
        IDBC dbc = IDBC(getDBC());

        tokenId = dbc.submitAgencyExpenditure(
            address(this),
            expenseType,
            amount,
            pdfSource,
            pageSource,
            uri
        );

        emit ExpenditureSubmitted(tokenId, expenseType, amount);
    }

    /**
     * @notice Revise an existing expenditure
     * @dev Only owner (document manager) can call this
     * @param tokenId Token ID to revise
     * @param expenseType Type of expense
     * @param amount New amount
     * @param pdfSource PDF source reference
     * @param pageSource Page number in PDF
     * @param uri New token URI
     * @param reason Reason for revision
     * @return newTokenId The new token ID after revision
     */
    function reviseExpenditure(
        uint256 tokenId,
        GAATypes.ExpenseType expenseType,
        uint256 amount,
        string calldata pdfSource,
        uint256 pageSource,
        string calldata uri,
        string calldata reason
    ) external onlyOwner returns (uint256 newTokenId) {
        IDBC dbc = IDBC(getDBC());

        newTokenId = dbc.reviseAgencyExpenditure(
            address(this),
            tokenId,
            expenseType,
            amount,
            pdfSource,
            pageSource,
            uri,
            reason
        );

        emit ExpenditureRevised(tokenId, newTokenId);
    }
}
