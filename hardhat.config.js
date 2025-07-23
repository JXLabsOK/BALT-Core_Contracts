require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    core_testnet: {
      url: process.env.CORE_TESTNET_RPC_URL || "https://rpc.test2.btcs.network",
      accounts: [process.env.PRIVATE_KEY],
      chainId: 1114,
    },
  },
};