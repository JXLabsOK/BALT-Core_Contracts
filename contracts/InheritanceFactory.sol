// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./InheritanceVault.sol";

contract InheritanceFactory {
    address public commissionWallet;
    uint256 public creationFee;

    mapping(address => address[]) public userVaults;

    event VaultCreated(
        address indexed owner,
        address indexed vault,
        address indexed beneficiary,
        uint256 maxInactivePeriod
    );

    constructor(address _commissionWallet, uint256 _creationFee) {
        require(_commissionWallet != address(0), "Invalid commission wallet");
        commissionWallet = _commissionWallet;
        creationFee = _creationFee;
    }

    function createVault(address beneficiary, uint256 maxInactivePeriod) external payable returns (address) {
        require(beneficiary != address(0), "beneficiary address is required");    
        require(maxInactivePeriod >= 1800, "Inactivity period too short"); // mínimo 30 minutos
        require(msg.value >= creationFee, "Insufficient fee");
        
        (bool success, ) = commissionWallet.call{value: msg.value}("");
        require(success, "Commission transfer failed");
        
        InheritanceVault vault = new InheritanceVault(
            msg.sender,
            beneficiary,
            maxInactivePeriod
        );

        userVaults[msg.sender].push(address(vault));

        emit VaultCreated(msg.sender, address(vault), beneficiary, maxInactivePeriod);
        return address(vault);
    }

    function getVaults(address owner) external view returns (address[] memory) {
        return userVaults[owner];
    }

    function updateCreationFee(uint256 newFee) external {
        require(msg.sender == commissionWallet, "Only commission wallet can update fee");
        creationFee = newFee;
    }

    function updateCommissionWallet(address newWallet) external {
        require(msg.sender == commissionWallet, "Only current wallet can update");
        require(newWallet != address(0), "Invalid new wallet");
        commissionWallet = newWallet;
    }
}
