// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract InheritanceVault {
    address public owner;
    address public beneficiary;
    uint256 public lastHeartbeat;
    uint256 public maxInactivePeriod;
    string public legacyMessage;
    string public fileCid; // 🆕 IPFS CID del archivo adjunto

    mapping(address => uint256) public erc20Balances;
    mapping(address => mapping(uint256 => bool)) public nftDeposited;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    event NativeClaimed(uint256 amount);
    event TokenClaimed(address token, uint256 amount);
    event NFTClaimed(address nft, uint256 tokenId);
    event MessageSet(string message);
    event FileAttached(string cid);
    event BeneficiaryAssigned(address indexed beneficiary);

    constructor(address _owner, address _beneficiary, uint256 _maxInactivePeriod) {
        owner = _owner;
        beneficiary = _beneficiary;
        maxInactivePeriod = _maxInactivePeriod;
        lastHeartbeat = block.timestamp;
    }

    receive() external payable {}

    function heartbeat() external onlyOwner {
        lastHeartbeat = block.timestamp;
    }

    function isInactive() public view returns (bool) {
        return block.timestamp > lastHeartbeat + maxInactivePeriod;
    }

    function claim() external {
        require(isInactive(), "Owner still active");

        if (beneficiary != address(0)) {
            require(msg.sender == beneficiary, "Only the designated beneficiary can claim");
        } else {
            beneficiary = msg.sender;
            emit BeneficiaryAssigned(msg.sender);
        }

        uint256 balance = address(this).balance;
        require(balance > 0, "No balance");
        payable(msg.sender).transfer(balance);
        emit NativeClaimed(balance);
    }

    function depositToken(address token, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be > 0");
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");
        erc20Balances[token] += amount;
    }

    function claimToken(address token) external {
        require(isInactive(), "Owner still active");

        if (beneficiary != address(0)) {
            require(msg.sender == beneficiary, "Only the designated beneficiary can claim");
        } else {
            beneficiary = msg.sender;
            emit BeneficiaryAssigned(msg.sender);
        }

        uint256 amount = erc20Balances[token];
        require(amount > 0, "No tokens");
        erc20Balances[token] = 0;
        require(IERC20(token).transfer(msg.sender, amount), "Token claim failed");
        emit TokenClaimed(token, amount);
    }

    function depositNFT(address nft, uint256 tokenId) external onlyOwner {
        IERC721(nft).transferFrom(msg.sender, address(this), tokenId);
        nftDeposited[nft][tokenId] = true;
    }

    function claimNFT(address nft, uint256 tokenId) external {
        require(isInactive(), "Owner still active");

        if (beneficiary != address(0)) {
            require(msg.sender == beneficiary, "Only the designated beneficiary can claim");
        } else {
            beneficiary = msg.sender;
            emit BeneficiaryAssigned(msg.sender);
        }

        require(nftDeposited[nft][tokenId], "NFT not available");
        nftDeposited[nft][tokenId] = false;
        IERC721(nft).transferFrom(address(this), msg.sender, tokenId);
        emit NFTClaimed(nft, tokenId);
    }

    function setLegacyMessage(string calldata _message) external onlyOwner {
        legacyMessage = _message;
        emit MessageSet(_message);
    }

    // Permitir al owner adjuntar un archivo por IPFS (solo se guarda el CID)
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
}