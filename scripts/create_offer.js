// scripts/create_offer.js
// Lender tạo offer: principal, interestBps, duration(s)
const P2P_ADDR = "<PASTE_CONTRACT_ADDRESS>";
const PRINCIPAL = "100";   // cUSD
const INTEREST_BPS = 500;  // 5%
const DURATION_SEC = 30 * 24 * 60 * 60; // 30 ngày

async function main() {
  const [lender] = await ethers.getSigners();
  const abi = (await (await fetch("/workspace/abi/P2PLending.abi.json")).json());
  const p2p = new ethers.Contract(P2P_ADDR, abi, lender);

  const principalWei = ethers.parseUnits(PRINCIPAL, 18);
  const tx = await p2p.createOffer(principalWei, INTEREST_BPS, DURATION_SEC);
  const rc = await tx.wait();

  const ev = rc.logs?.find(l => l.fragment?.name === "OfferCreated");
  console.log("OfferCreated id:", ev ? ev.args[0].toString() : "(xem explorer)");
}
main().catch(console.error);
