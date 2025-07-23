const hre = require("hardhat");

async function main() {
  const [signer] = await hre.ethers.getSigners();  
  const commissionWallet = "0xeCd960325d5FFd74262876FB36dc732f8d9c7b62"; // tu dirección de comisiones
  const creationFee = hre.ethers.parseEther("0.01"); // o el valor que definas

  console.log("Deploying InheritanceFactory...");

  const InheritanceFactory = await hre.ethers.getContractFactory("InheritanceFactory", signer);
  const factory = await InheritanceFactory.deploy(commissionWallet, creationFee);
  await factory.waitForDeployment();

  console.log(`✅ InheritanceFactory deployed at: ${factory.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});