// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@dpa-oss/dpa/contracts/DPA.sol";
import "../shared/GAATypes.sol";

/**
 * @title SPFDPA
 * @dev DPA implementation for Special Purpose Funds
 *      Managed by responsible department during minting phase
 */
contract SPFDPA is DPA {
    // ============ Events ============

    /// @notice Emitted when SPF content is stored
    event SPFStored(
        uint256 indexed tokenId,
        string fundingSourceCode,
        string spfCategoryName,
        GAATypes.ExpenseType expenseType,
        uint256 amount
    );

    // ============ Constructor ============

    /**
     * @param orchestrator_ The DBC contract address (orchestrator)
     */
    constructor(
        address orchestrator_
    ) DPA("GAA Special Purpose Funds", "GAA-SPF", orchestrator_) {}

    // ============ View Functions ============

    /**
     * @notice Decodes and returns the SPF content for a token
     * @param tokenId Token to query
     * @return content The decoded SPFContent struct
     */
    function getSPFContent(
        uint256 tokenId
    ) external view returns (GAATypes.SPFContent memory content) {
        bytes memory rawContent = this.tokenContent(tokenId);
        content = abi.decode(rawContent, (GAATypes.SPFContent));
    }

    // ============ Internal Functions ============

    /**
     * @dev Validates that content can be decoded as SPFContent
     * @param content The encoded content to validate
     */
    function _validateContent(bytes calldata content) internal pure override {
        // Attempt to decode - will revert if invalid
        abi.decode(content, (GAATypes.SPFContent));
    }

    /**
     * @notice Helper to encode SPFContent for minting
     * @param content The SPFContent struct to encode
     * @return Encoded bytes
     */
    function encodeContent(
        GAATypes.SPFContent calldata content
    ) external pure returns (bytes memory) {
        return abi.encode(content);
    }
}
