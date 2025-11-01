// scripts/repay.js
// Borrower trả nợ: tự tính repayAmount -> approve -> repay
const P2P_ADDR = "<PASTE_CONTRACT_ADDRESS>";
const CUSD     = "0xEF4d55D6dE8e8d73232827Cd1e9b2F2dBb45bC80";
const OFFER_ID = 0; // đổi đúng ID

async function main() {
  const [borrower] = await ethers.getSigners();

  const P2P_ABI   = await (await fetch("/workspace/abi/P2PLending.abi.json")).json();
  const ERC20_ABI = await (await fetch("/workspace/abi/ERC20.min.abi.json")).json();

  const p2p  = new ethers.Contract(P2P_ADDR, P2P_ABI, borrower);
  const cUSD = new ethers.Contract(CUSD,     ERC20_ABI, borrower);

  const amount = await p2p.repayAmount(OFFER_ID);
  console.log("repayAmount:", amount.toString());

  await (await cUSD.approve(P2P_ADDR, amount)).wait();
  await (await p2p.repay(OFFER_ID)).wait();
  console.log("✅ Repay done");
}
main().catch(console.error);
