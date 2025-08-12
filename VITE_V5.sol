// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OVM
 */
interface IOVM {
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
    function acceptOwnership() external;
    function grantRoles(address user, uint256 roles) external;
}

/**
 * @title Validator Inheritance & Trust Executor (VITE) V5
 * @author hackworth.eth
 * @notice The final version, granting all available roles to the beneficial owner.
 */
contract VITE_V5 {
    //========================================================================
    // State Variables
    //========================================================================

    address public beneficialOwner;
    address public immutable heir;
    IOVM public immutable ovmContract;

    // --- Bitmask Role Constants (from your screenshot) ---
    uint256 public constant WITHDRAWAL_ROLE = 1;
    uint256 public constant CONSOLIDATION_ROLE = 2;
    uint256 public constant SET_PRINCIPAL_ROLE = 4;
    uint256 public constant RECOVER_FUNDS_ROLE = 8;

    // --- Time-lock Constants (6 month activity check-in) ---
    uint256 public constant CHECK_IN_PERIOD = 180 days;
    uint256 public constant GRACE_PERIOD = 180 days;

    // --- State ---
    uint256 public lastCheckIn;
    bool public successionTriggered;

    //========================================================================
    // Events & Modifier
    //========================================================================
    event OVMOwnershipAccepted(address indexed ovmContract, address indexed viteContract);
    event CheckedIn(address indexed beneficialOwner, uint256 timestamp);
    event SuccessionInitiated(address indexed heir, address indexed ovm, uint256 timestamp);
    event AllRolesGranted(address indexed grantee, uint256 roles);

    modifier onlyBeneficialOwner() {
        require(msg.sender == beneficialOwner, "VITE: Caller is not the beneficial owner");
        _;
    }

    //========================================================================
    // Constructor
    //========================================================================
    constructor(address _beneficialOwner, address _heir, address _ovmContractAddress) {
        require(_beneficialOwner != address(0), "VITE: Beneficial owner cannot be zero address");
        require(_heir != address(0), "VITE: Heir cannot be zero address");
        require(_ovmContractAddress != address(0), "VITE: OVM contract cannot be zero address");
        
        beneficialOwner = _beneficialOwner;
        heir = _heir;
        ovmContract = IOVM(_ovmContractAddress);
        lastCheckIn = block.timestamp;
    }

    //========================================================================
    // Setup & Management Functions
    //========================================================================

    function acceptOVMOwnership() external onlyBeneficialOwner {
        require(ovmContract.owner() != address(this), "VITE: Already the owner of the OVM");
        ovmContract.acceptOwnership();
        emit OVMOwnershipAccepted(address(ovmContract), address(this));
    }

    function grantAllRolesToSelf() external onlyBeneficialOwner {
        uint256 allRoles = WITHDRAWAL_ROLE + CONSOLIDATION_ROLE + SET_PRINCIPAL_ROLE + RECOVER_FUNDS_ROLE; // 1+2+4+8 = 15
        ovmContract.grantRoles(beneficialOwner, allRoles);
        emit AllRolesGranted(beneficialOwner, allRoles);
    }

    //========================================================================
    // Inheritance Workflow Functions
    //========================================================================

    function checkIn() external onlyBeneficialOwner {
        lastCheckIn = block.timestamp;
        emit CheckedIn(beneficialOwner, block.timestamp);
    }

    function initiateSuccession() external {
        require(msg.sender == heir, "VITE: Caller is not the heir");
        require(!successionTriggered, "VITE: Succession has already been triggered");
        
        uint256 successionReadyTime = lastCheckIn + CHECK_IN_PERIOD + GRACE_PERIOD;
        require(block.timestamp >= successionReadyTime, "VITE: Inactivity period has not elapsed");

        successionTriggered = true;
        ovmContract.transferOwnership(heir);
        emit SuccessionInitiated(heir, address(ovmContract), block.timestamp);
    }
}
