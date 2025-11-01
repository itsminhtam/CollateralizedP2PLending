// scripts/approve.js
// Approve cUSD cho contract P2PLending.
const P2P_ADDR = "<PASTE_CONTRACT_ADDRESS>"; // dán địa chỉ sau deploy
const CUSD     = "0xEF4d55D6dE8e8d73232827Cd1e9b2F2dBb45bC80";
const AMOUNT   = "100"; // số cUSD (không 18 decimals)

async function main() {
  const [signer] = await ethers.getSigners();
  const abi = await (await fetch("/workspace/abi/ERC20.min.abi.json")).json();
  const token = new ethers.Contract(CUSD, abi, signer);

  const dec = await token.decimals();
  const value = ethers.parseUnits(AMOUNT, dec);

  console.log("Approving", AMOUNT, "cUSD for", P2P_ADDR);
  const tx = await token.approve(P2P_ADDR, value);
  await tx.wait();
  console.log("✅ Approved");
}
main().catch(console.error);
