// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@dpa-oss/dpa/contracts/DPA.sol";
import "../shared/GAATypes.sol";

/**
 * @title AgencyBudgetDPA
 * @dev DPA implementation for Agency Budget expenditures
 *      Content auto-populated by DBC with department/agency info
 */
contract AgencyBudgetDPA is DPA {
    // ============ Events ============

    /// @notice Emitted when agency budget content is stored
    event AgencyBudgetStored(
        uint256 indexed tokenId,
        string departmentCode,
        string agencyCode,
        GAATypes.ExpenseType expenseType,
        uint256 amount
    );

    // ============ Constructor ============

    /**
     * @param orchestrator_ The DBC contract address (orchestrator)
     */
    constructor(
        address orchestrator_
    ) DPA("GAA Agency Budget", "GAA-AGENCY", orchestrator_) {
        _baseTokenURI = "https://emerald-certain-muskox-778.mypinata.cloud/ipfs/";
    }

    // ============ View Functions ============

    /**
     * @notice Decodes and returns the agency budget content for a token
     * @param tokenId Token to query
     * @return content The decoded AgencyBudgetContent struct
     */
    function getAgencyBudgetContent(
        uint256 tokenId
    ) external view returns (GAATypes.AgencyBudgetContent memory content) {
        bytes memory rawContent = this.tokenContent(tokenId);
        content = abi.decode(rawContent, (GAATypes.AgencyBudgetContent));
    }

    // ============ Internal Functions ============

    /**
     * @dev Validates that content can be decoded as AgencyBudgetContent
     * @param content The encoded content to validate
     */
    function _validateContent(bytes calldata content) internal pure override {
        // Attempt to decode - will revert if invalid
        abi.decode(content, (GAATypes.AgencyBudgetContent));
    }

    // ============ Helper Functions ============

    /**
     * @notice Helper to encode AgencyBudgetContent for minting
     * @param expenseType The expense type
     * @param amount The amount value
     * @param pdfSource PDF source reference
     * @param pageSource Page number in PDF
     * @param departmentCode Department code
     * @param departmentName Department name
     * @param agencyCode Agency code
     * @param agencyName Agency name
     * @return Encoded bytes
     */
    function encodeContent(
        GAATypes.ExpenseType expenseType,
        uint256 amount,
        string calldata pdfSource,
        uint256 pageSource,
        string calldata departmentCode,
        string calldata departmentName,
        string calldata agencyCode,
        string calldata agencyName
    ) external pure returns (bytes memory) {
        return
            abi.encode(
                GAATypes.AgencyBudgetContent({
                    expenseType: expenseType,
                    amount: amount,
                    pdfSource: pdfSource,
                    pageSource: pageSource,
                    departmentCode: departmentCode,
                    departmentName: departmentName,
                    agencyCode: agencyCode,
                    agencyName: agencyName
                })
            );
    }
}
