// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../shared/GAATypes.sol";

/**
 * @title IAgencyBudgetDPA
 * @dev Interface for AgencyBudgetDPA contract
 */
interface IAgencyBudgetDPA {
    function orchestrator() external view returns (address);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function tokenContent(uint256 tokenId) external view returns (bytes memory);

    function mint(
        address to,
        string calldata uri,
        bytes calldata content
    ) external returns (uint256 tokenId);

    function revise(
        uint256 tokenId,
        string calldata uri,
        bytes calldata content,
        string calldata reason
    ) external returns (uint256 newTokenId);

    function encodeContent(
        GAATypes.ExpenseType expenseType,
        uint256 amount,
        string calldata pdfSource,
        uint256 pageSource,
        string calldata departmentCode,
        string calldata departmentName,
        string calldata agencyCode,
        string calldata agencyName
    ) external pure returns (bytes memory);

    function getAgencyBudgetContent(
        uint256 tokenId
    ) external view returns (GAATypes.AgencyBudgetContent memory);
}

/**
 * @title ISPFDPA
 * @dev Interface for SPFDPA contract
 */
interface ISPFDPA {
    function orchestrator() external view returns (address);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function tokenContent(uint256 tokenId) external view returns (bytes memory);

    function mint(
        address to,
        string calldata uri,
        bytes calldata content
    ) external returns (uint256 tokenId);

    function revise(
        uint256 tokenId,
        string calldata uri,
        bytes calldata content,
        string calldata reason
    ) external returns (uint256 newTokenId);

    function encodeContent(
        GAATypes.SPFContent calldata content
    ) external pure returns (bytes memory);

    function getSPFContent(
        uint256 tokenId
    ) external view returns (GAATypes.SPFContent memory);
}

/**
 * @title IBESFDPA
 * @dev Interface for BESFDPA contract
 */
interface IBESFDPA {
    function orchestrator() external view returns (address);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function tokenContent(uint256 tokenId) external view returns (bytes memory);

    function mint(
        address to,
        string calldata uri,
        bytes calldata content
    ) external returns (uint256 tokenId);

    function revise(
        uint256 tokenId,
        string calldata uri,
        bytes calldata content,
        string calldata reason
    ) external returns (uint256 newTokenId);
}
