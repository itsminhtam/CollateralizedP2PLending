// scripts/withdraw_lender.js
// Lender rút gốc + lãi
const P2P_ADDR = "<PASTE_CONTRACT_ADDRESS>";
const OFFER_ID = 0; // đổi đúng ID

async function main() {
  const [lender] = await ethers.getSigners();
  const abi = await (await fetch("/workspace/abi/P2PLending.abi.json")).json();
  const p2p = new ethers.Contract(P2P_ADDR, abi, lender);

  await (await p2p.withdrawLender(OFFER_ID)).wait();
  console.log("✅ withdrawLender(", OFFER_ID, ") OK");
}
main().catch(console.error);
