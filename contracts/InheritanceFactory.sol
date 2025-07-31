// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./InheritanceVault.sol";

contract InheritanceFactory {
    address public commissionWallet;
    uint256 public creationFee;

    address[] public allVaults;
    mapping(address => address[]) public vaultsByCreator;

    event VaultCreated(
        address indexed creator,
        address indexed vaultAddress,
        address indexed beneficiary,
        uint256 inactivityPeriod
    );

    constructor(address _commissionWallet, uint256 _creationFee) {
        require(_commissionWallet != address(0), "Invalid commission wallet");
        commissionWallet = _commissionWallet;
        creationFee = _creationFee;
    }

    function createVault(address _beneficiary, uint256 _inactivityPeriod) external payable returns (address) {
        require(_beneficiary != address(0), "Beneficiary required");
        require(_inactivityPeriod >= 1800, "Min inactivity: 30 min");
        require(msg.value >= creationFee, "Insufficient fee");

        // Transferir comisión correctamente con calldata vacío
        (bool sent, ) = commissionWallet.call{value: msg.value}("");
        require(sent, "Fee transfer failed");

        // Crear vault
        InheritanceVault vault = new InheritanceVault(msg.sender, _beneficiary, _inactivityPeriod);

        allVaults.push(address(vault));
        vaultsByCreator[msg.sender].push(address(vault));

        emit VaultCreated(msg.sender, address(vault), _beneficiary, _inactivityPeriod);

        return address(vault);
    }

    function getVaultsByCreator(address _creator) external view returns (address[] memory) {
        return vaultsByCreator[_creator];
    }

    function getAllVaults() external view returns (address[] memory) {
        return allVaults;
    }

    function updateCreationFee(uint256 _newFee) external {
        require(msg.sender == commissionWallet, "Only commission wallet");
        creationFee = _newFee;
    }

    function updateCommissionWallet(address _newWallet) external {
        require(msg.sender == commissionWallet, "Only current wallet");
        require(_newWallet != address(0), "Invalid wallet");
        commissionWallet = _newWallet;
    }
}