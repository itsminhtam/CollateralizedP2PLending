// scripts/deploy.js
// Deploy P2PLending trên Celo Sepolia từ Remix Script Runner.
const CUSD = "0xEF4d55D6dE8e8d73232827Cd1e9b2F2dBb45bC80"; // cUSD Sepolia

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", await deployer.getAddress());

  const Factory = await ethers.getContractFactory("P2PLending");
  const contract = await Factory.deploy(CUSD);
  await contract.waitForDeployment();

  console.log("P2PLending deployed at:", await contract.getAddress());
}

main().then(()=>console.log("✅ Done")).catch(console.error);
