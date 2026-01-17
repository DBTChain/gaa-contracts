// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@dpa-oss/dpa/contracts/DPA.sol";

/**
 * @title BESFDPA
 * @dev DPA implementation for Budget of Expenditures and Sources of Financing
 *      Content struct TBD - accepts any bytes for now
 *      Managed by responsible department during minting phase
 */
contract BESFDPA is DPA {
    // ============ Constructor ============

    /**
     * @param orchestrator_ The DBC contract address (orchestrator)
     */
    constructor(
        address orchestrator_
    ) DPA("GAA BESF", "GAA-BESF", orchestrator_) {}

    // ============ Internal Functions ============

    /**
     * @dev No content validation - BESF struct TBD
     * @param content The encoded content (accepts any bytes)
     */
    function _validateContent(bytes calldata content) internal pure override {
        // No validation for now - struct to be defined later
        // Just ensure content is not empty
        require(content.length > 0, "BESFDPA: empty content");
    }
}
