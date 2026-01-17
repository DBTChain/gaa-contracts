// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title GAAErrors
 * @dev Custom error definitions for GAA contracts
 */
library GAAErrors {
    // ============ Phase Errors ============

    /// @dev Action not allowed in current phase
    error InvalidPhase();

    /// @dev Cannot transition to the requested phase
    error InvalidPhaseTransition();

    // ============ Department Errors ============

    /// @dev Department code already exists
    error DepartmentAlreadyExists();

    /// @dev Department not found
    error DepartmentNotFound();

    /// @dev Caller is not a registered department
    error NotADepartment();

    /// @dev Caller is not the responsible department
    error NotResponsibleDepartment();

    // ============ Agency Errors ============

    /// @dev Agency code already exists
    error AgencyAlreadyExists();

    /// @dev Agency not found
    error AgencyNotFound();

    /// @dev Caller is not a registered agency
    error NotAnAgency();

    /// @dev Agency does not belong to the department
    error AgencyNotInDepartment();

    // ============ DPA Errors ============

    /// @dev DPA contract already deployed for this fiscal year
    error DPAAlreadyDeployed();

    /// @dev DPA contract not deployed for this fiscal year
    error DPANotDeployed();

    /// @dev Cannot manage DPA token not owned by caller
    error NotTokenOwner();

    // ============ General Errors ============

    /// @dev Empty string provided where non-empty expected
    error EmptyString();

    /// @dev Invalid address (zero address)
    error InvalidAddress();

    /// @dev Caller not authorized for this action
    error Unauthorized();

    /// @dev Action not allowed by DBC
    error NotAllowedByDBC();
}
