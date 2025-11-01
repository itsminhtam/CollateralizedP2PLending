// scripts/take_loan.js
// Borrower nhận khoản vay: truyền offerId
const P2P_ADDR = "<PASTE_CONTRACT_ADDRESS>";
const OFFER_ID = 0; // đổi đúng ID

async function main() {
  const [borrower] = await ethers.getSigners();
  const abi = await (await fetch("/workspace/abi/P2PLending.abi.json")).json();
  const p2p = new ethers.Contract(P2P_ADDR, abi, borrower);

  await (await p2p.takeLoan(OFFER_ID)).wait();
  console.log("✅ takeLoan(", OFFER_ID, ") OK");
}
main().catch(console.error);
