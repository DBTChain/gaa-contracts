// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title GAATypes
 * @dev Shared types for GAA contracts ecosystem
 */
library GAATypes {
    /// @notice Lifecycle phases for the GAA budget cycle
    enum Phase {
        Preparation,
        Minting,
        Enactment,
        Finality
    }

    /// @notice Expense type enumeration matching UACS codes
    /// @dev Values map to: 1=PersonnelServices, 2=MOOE, 3=CapitalOutlays, 6=FinancialExpenses
    enum ExpenseType {
        PersonnelServices, // Code: 1
        MOOE, // Code: 2
        CapitalOutlays, // Code: 3
        FinancialExpenses // Code: 6
    }

    /// @notice Base content structure for all DPA tokens
    struct BaseContent {
        ExpenseType expenseType;
        uint256 amount;
        string pdfSource;
        uint256 pageSource;
    }

    /// @notice Agency Budget extended content - includes department and agency info
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

    /// @notice SPF (Special Purpose Fund) extended content
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

    /// @notice Input struct for SPF submission to avoid stack too deep
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

    /// @notice Input struct for SPF revision to avoid stack too deep
    struct SPFRevisionInput {
        uint256 tokenId;
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
        string reason;
    }

    /// @notice Helper to get expense type code
    function getExpenseTypeCode(
        ExpenseType expenseType
    ) internal pure returns (uint8) {
        if (expenseType == ExpenseType.PersonnelServices) return 1;
        if (expenseType == ExpenseType.MOOE) return 2;
        if (expenseType == ExpenseType.CapitalOutlays) return 3;
        if (expenseType == ExpenseType.FinancialExpenses) return 6;
        return 0;
    }

    /// @notice Helper to get expense type name
    function getExpenseTypeName(
        ExpenseType expenseType
    ) internal pure returns (string memory) {
        if (expenseType == ExpenseType.PersonnelServices)
            return "Personnel Services";
        if (expenseType == ExpenseType.MOOE)
            return "Maintenance and Other Operating Expenses";
        if (expenseType == ExpenseType.CapitalOutlays) return "Capital Outlays";
        if (expenseType == ExpenseType.FinancialExpenses)
            return "Financial Expenses";
        return "";
    }
}
