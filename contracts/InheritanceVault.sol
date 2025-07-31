// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract InheritanceVault {
    address public immutable owner;
    address public immutable beneficiary;
    uint256 public immutable maxInactivePeriod;
    uint256 public lastHeartbeat;
    string public legacyMessage;
    string public fileCid;

    enum Status { Active, Claimed, Cancelled }
    Status public inheritanceStatus = Status.Active;

    mapping(address => uint256) public erc20Balances;
    mapping(address => mapping(uint256 => bool)) public nftDeposited;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Only beneficiary");
        _;
    }

    modifier isClaimable() {
        require(isInactive(), "Owner still active");
        require(inheritanceStatus == Status.Active, "Inheritance is not active");
        _;
    }

    event NativeClaimed(uint256 amount);
    event TokenClaimed(address indexed token, uint256 amount);
    event NFTClaimed(address indexed nft, uint256 tokenId);
    event MessageSet(string message);
    event FileAttached(string cid);
    event InheritanceCancelled(address indexed owner, uint256 refundedAmount);
    event HeartbeatUpdated(address indexed owner, uint256 timestamp);

    constructor(address _owner, address _beneficiary, uint256 _maxInactivePeriod) {
        require(_owner != address(0), "Owner address required");
        require(_beneficiary != address(0), "Beneficiary address required");
        require(_maxInactivePeriod >= 1800, "Inactivity period must be >= 30 min");

        owner = _owner;
        beneficiary = _beneficiary;
        maxInactivePeriod = _maxInactivePeriod;
        lastHeartbeat = block.timestamp;
    }

    receive() external payable {}

    function heartbeat() external onlyOwner {
        lastHeartbeat = block.timestamp;
        emit HeartbeatUpdated(msg.sender, lastHeartbeat);
    }

    function isInactive() public view returns (bool) {
        return block.timestamp > lastHeartbeat + maxInactivePeriod;
    }

    // ============ Native Coin Claim ============
    function claim() external onlyBeneficiary isClaimable {
        uint256 balance = address(this).balance;
        require(balance > 0, "No native balance");

        inheritanceStatus = Status.Claimed;

        (bool success, ) = payable(beneficiary).call{value: balance}("");
        require(success, "Native transfer failed");

        emit NativeClaimed(balance);
    }

    // ============ ERC20 ============
    function depositToken(address token, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be > 0");
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        erc20Balances[token] += amount;
    }

    function claimToken(address token) external onlyBeneficiary isClaimable {
        uint256 amount = erc20Balances[token];
        require(amount > 0, "No token balance");

        inheritanceStatus = Status.Claimed;
        erc20Balances[token] = 0;

        require(IERC20(token).transfer(msg.sender, amount), "ERC20 transfer failed");
        emit TokenClaimed(token, amount);
    }

    // ============ NFT ============
    function depositNFT(address nft, uint256 tokenId) external onlyOwner {
        require(!nftDeposited[nft][tokenId], "NFT already deposited");
        IERC721(nft).transferFrom(msg.sender, address(this), tokenId);
        nftDeposited[nft][tokenId] = true;
    }

    function claimNFT(address nft, uint256 tokenId) external onlyBeneficiary isClaimable {
        require(nftDeposited[nft][tokenId], "NFT not found");

        inheritanceStatus = Status.Claimed;
        nftDeposited[nft][tokenId] = false;

        IERC721(nft).transferFrom(address(this), msg.sender, tokenId);
        emit NFTClaimed(nft, tokenId);
    }

    // ============ Metadata ============
    function setLegacyMessage(string calldata _message) external onlyOwner {
        legacyMessage = _message;
        emit MessageSet(_message);
    }

    function attachFile(string calldata _cid) external onlyOwner {
        fileCid = _cid;
        emit FileAttached(_cid);
    }

    function getLegacyMessage() external view returns (string memory) {
        return legacyMessage;
    }

    function getFileCid() external view returns (string memory) {
        return fileCid;
    }

    // ============ Cancel ============
    function cancelInheritance() public onlyOwner {
        require(inheritanceStatus == Status.Active, "Already finalized");

        uint256 refund = address(this).balance;
        inheritanceStatus = Status.Cancelled;

        (bool success, ) = owner.call{value: refund}("");
        require(success, "Refund failed");

        emit InheritanceCancelled(owner, refund);
    }
}