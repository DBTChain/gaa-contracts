// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./GAATypes.sol";

/**
 * @title IDepartment
 * @dev Interface for Department contract
 */
interface IDepartment {
    function code() external view returns (string memory);

    function name() external view returns (string memory);

    function mainAgencyName() external view returns (string memory);

    function mainAgency() external view returns (address);

    function dbc() external view returns (address);

    function addAgency(
        string calldata agencyCode,
        string calldata agencyName,
        address agencyOwner
    ) external returns (address);

    function removeAgency(string calldata agencyCode) external;

    function getAgency(
        string calldata agencyCode
    ) external view returns (address);

    function isAgency(address agencyAddress) external view returns (bool);

    function getAgencyCount() external view returns (uint256);

    function getAllAgencyCodes() external view returns (string[] memory);
}

/**
 * @title IAgency
 * @dev Interface for Agency contract
 */
interface IAgency {
    function code() external view returns (string memory);

    function name() external view returns (string memory);

    function department() external view returns (address);

    function dbc() external view returns (address);

    function owner() external view returns (address);

    function getDepartmentCode() external view returns (string memory);

    function getDepartmentName() external view returns (string memory);

    function submitExpenditure(
        GAATypes.ExpenseType expenseType,
        uint256 amount,
        string calldata pdfSource,
        uint256 pageSource,
        string calldata uri
    ) external returns (uint256 tokenId);

    function reviseExpenditure(
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
 * @title IDBC
 * @dev Interface for DBC orchestrator contract
 */
interface IDBC {
    function currentPhase() external view returns (GAATypes.Phase);

    function fiscalYear() external view returns (uint256);

    function responsibleMintingDept() external view returns (address);

    function responsibleEnactmentDept() external view returns (address);

    function getDepartment(
        string calldata departmentCode
    ) external view returns (address);

    function isDepartment(address deptAddress) external view returns (bool);

    function agencyBudgetDPA(uint256 year) external view returns (address);

    function spfDPA(uint256 year) external view returns (address);

    function besfDPA(uint256 year) external view returns (address);

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
