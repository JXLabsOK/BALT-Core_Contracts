# 🧾 Blockchain Autonomous Legacy Trust – BΔLT

This repository contains the smart contracts powering **BΔLTCore (Blockchain Autonomous Legacy Trust)** — a decentralized inheritance protocol designed to operate on **Coredao** blockchains.

## 📦 Project Structure

- **InheritanceFactory.sol**  
  The factory contract responsible for deploying new instances of InheritanceVault.sol.
  It maintains a registry of all Vaults created by users and acts as the entry point for configuring digital inheritance.

  Key features:
  - Deploys one vault per user (per request)
  - Emits events upon creation for frontend tracking
  - Does not require knowledge of the asset type (CORE or ERC-20)
  - Designed for scalability across networks and token standards

- **InheritanceVault.sol**  
  A personalized autonomous vault deployed per user.
  It securely holds native or ERC-20 assets and governs inheritance based on wallet inactivity.

  Key features:
  - Optional beneficiary assignment at creation, or automatic assignment on first claim
  - Customizable inactivity period (e.g., 180 days)
  - Manual claim by the heir if the owner becomes inactive
  - Allows deposit of:
  - CORE tokens (native)
  - ERC-20 tokens (e.g., USDT)
  - ERC-721 NFTs
  - Optional IPFS file attachment and legacy message
  - Owner can check in to reset the inactivity timer
  - Immutable and trustless once deployed — logic is fully enforced on-chain

## ⚙️ Requirements

- Node.js & npm
- Hardhat (development environment)
- Metamask or any Web3-compatible wallet
- An RSK node or public RPC endpoint

## 🚀 Getting Started

1. Clone the repository:

   ```bash
   git clone https://github.com/your-org/inheritance-contracts.git
   cd inheritance-contracts