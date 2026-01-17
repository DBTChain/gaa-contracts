// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Agency.sol";
import "./shared/GAATypes.sol";
import "./shared/GAAErrors.sol";

// Forward declaration
interface IDBCForDepartment {
    function currentPhase() external view returns (GAATypes.Phase);
}

/**
 * @title Department
 * @dev Department contract representing a government department
 *      Manages agencies and links to the DBC orchestrator
 */
contract Department is Ownable {
    // ============ State Variables ============

    /// @notice Department code (e.g., "DBM")
    string public code;

    /// @notice Department name (e.g., "Department of Budget and Management")
    string public name;

    /// @notice Main agency name
    string public mainAgencyName;

    /// @notice Reference to DBC orchestrator contract
    address public dbc;

    /// @notice Main agency contract (auto-created)
    address public mainAgency;

    /// @notice Mapping of agency code to Agency contract address
    mapping(string => address) private _agencies;

    /// @notice Array of agency codes for enumeration
    string[] private _agencyCodes;

    // ============ Events ============

    /// @notice Emitted when an agency is added
    event AgencyAdded(string indexed codeHash, string code, address agency);

    /// @notice Emitted when an agency is removed
    event AgencyRemoved(string indexed codeHash, string code);

    // ============ Modifiers ============

    /// @dev Only allow during Preparation phase
    modifier onlyPreparation() {
        if (
            IDBCForDepartment(dbc).currentPhase() != GAATypes.Phase.Preparation
        ) {
            revert GAAErrors.InvalidPhase();
        }
        _;
    }

    // ============ Constructor ============

    /**
     * @param _code Department code
     * @param _name Department name
     * @param _mainAgencyName Name for the main agency
     * @param _dbc DBC orchestrator contract address
     * @param mainAgencyOwner Owner of the main agency (document manager)
     */
    constructor(
        string memory _code,
        string memory _name,
        string memory _mainAgencyName,
        address _dbc,
        address mainAgencyOwner
    ) Ownable(msg.sender) {
        if (bytes(_code).length == 0) revert GAAErrors.EmptyString();
        if (bytes(_name).length == 0) revert GAAErrors.EmptyString();
        if (bytes(_mainAgencyName).length == 0) revert GAAErrors.EmptyString();
        if (_dbc == address(0)) revert GAAErrors.InvalidAddress();
        if (mainAgencyOwner == address(0)) revert GAAErrors.InvalidAddress();

        code = _code;
        name = _name;
        mainAgencyName = _mainAgencyName;
        dbc = _dbc;

        // Create main agency with department code as agency code
        Agency agency = new Agency(
            _code, // Use department code as main agency code
            _mainAgencyName,
            address(this),
            mainAgencyOwner
        );

        mainAgency = address(agency);
        _agencies[_code] = mainAgency;
        _agencyCodes.push(_code);

        emit AgencyAdded(_code, _code, mainAgency);
    }

    // ============ Agency Management ============

    /**
     * @notice Add a new agency to this department
     * @dev Only callable by owner during Preparation phase
     * @param agencyCode Unique agency code
     * @param agencyName Agency name
     * @param agencyOwner Owner (document manager) of the agency
     * @return agencyAddress The deployed Agency contract address
     */
    function addAgency(
        string calldata agencyCode,
        string calldata agencyName,
        address agencyOwner
    ) external onlyOwner onlyPreparation returns (address agencyAddress) {
        if (bytes(agencyCode).length == 0) revert GAAErrors.EmptyString();
        if (bytes(agencyName).length == 0) revert GAAErrors.EmptyString();
        if (agencyOwner == address(0)) revert GAAErrors.InvalidAddress();
        if (_agencies[agencyCode] != address(0))
            revert GAAErrors.AgencyAlreadyExists();

        Agency agency = new Agency(
            agencyCode,
            agencyName,
            address(this),
            agencyOwner
        );

        agencyAddress = address(agency);
        _agencies[agencyCode] = agencyAddress;
        _agencyCodes.push(agencyCode);

        emit AgencyAdded(agencyCode, agencyCode, agencyAddress);
    }

    /**
     * @notice Remove an agency from this department
     * @dev Only callable by owner during Preparation phase
     * @param agencyCode Code of the agency to remove
     */
    function removeAgency(
        string calldata agencyCode
    ) external onlyOwner onlyPreparation {
        if (_agencies[agencyCode] == address(0))
            revert GAAErrors.AgencyNotFound();

        // Cannot remove main agency
        if (keccak256(bytes(agencyCode)) == keccak256(bytes(code))) {
            revert GAAErrors.Unauthorized();
        }

        delete _agencies[agencyCode];

        // Remove from array
        for (uint256 i = 0; i < _agencyCodes.length; i++) {
            if (
                keccak256(bytes(_agencyCodes[i])) ==
                keccak256(bytes(agencyCode))
            ) {
                _agencyCodes[i] = _agencyCodes[_agencyCodes.length - 1];
                _agencyCodes.pop();
                break;
            }
        }

        emit AgencyRemoved(agencyCode, agencyCode);
    }

    // ============ View Functions ============

    /**
     * @notice Get agency address by code
     * @param agencyCode Agency code to lookup
     * @return Agency contract address
     */
    function getAgency(
        string calldata agencyCode
    ) external view returns (address) {
        return _agencies[agencyCode];
    }

    /**
     * @notice Get all agency codes
     * @return Array of agency codes
     */
    function getAllAgencyCodes() external view returns (string[] memory) {
        return _agencyCodes;
    }

    /**
     * @notice Get total number of agencies
     * @return Count of agencies
     */
    function getAgencyCount() external view returns (uint256) {
        return _agencyCodes.length;
    }

    /**
     * @notice Check if an address is an agency of this department
     * @param agencyAddress Address to check
     * @return True if address is a registered agency
     */
    function isAgency(address agencyAddress) external view returns (bool) {
        for (uint256 i = 0; i < _agencyCodes.length; i++) {
            if (_agencies[_agencyCodes[i]] == agencyAddress) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Get agency info by address
     * @param agencyAddress Agency contract address
     * @return agencyCode Agency code
     * @return agencyName Agency name
     */
    function getAgencyInfo(
        address agencyAddress
    )
        external
        view
        returns (string memory agencyCode, string memory agencyName)
    {
        Agency agency = Agency(agencyAddress);
        return (agency.code(), agency.name());
    }
}
