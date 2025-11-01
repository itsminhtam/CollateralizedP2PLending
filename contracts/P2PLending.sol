// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title P2PLending (Celo Sepolia version)
 * @notice P2P Lending tối giản dùng cUSD làm đơn vị cho vay/trả.
 * 
 * Quy trình:
 * - Lender gửi cUSD vào hợp đồng (escrow) tạo offer.
 * - Borrower nhận khoản vay (takeLoan).
 * - Borrower hoàn trả gốc + lãi (repay).
 * - Lender rút tiền về (withdrawLender).
 * 
 * Lãi suất tính đơn theo basis points (100 bps = 1%).
 */

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Nếu Remix không tải được OpenZeppelin, thay bằng import từ GitHub:
// import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v5.0.2/contracts/security/ReentrancyGuard.sol";
// import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v5.0.2/contracts/token/ERC20/IERC20.sol";

contract P2PLending is ReentrancyGuard {
    IERC20 public immutable cUSD;

    enum OfferStatus { Funded, Taken, Repaid, Cancelled }

    struct Offer {
        address lender;
        address borrower;
        uint256 principal;      // số tiền (cUSD, decimals 18)
        uint256 interestBps;    // 100 bps = 1%
        uint256 duration;       // thời hạn (giây)
        uint256 startAt;        // thời điểm borrower nhận tiền
        OfferStatus status;
    }

    uint256 public nextOfferId;
    mapping(uint256 => Offer) public offers;

    // ======= Sự kiện =======
    event OfferCreated(uint256 indexed id, address indexed lender, uint256 principal, uint256 interestBps, uint256 duration);
    event OfferCancelled(uint256 indexed id);
    event LoanTaken(uint256 indexed id, address indexed borrower);
    event LoanRepaid(uint256 indexed id, uint256 repayAmount);

    // ======= Lỗi tuỳ chỉnh =======
    error NotLender();
    error NotBorrower();
    error BadStatus();
    error TransferFailed();

    constructor(address cUSDAddress) {
        require(cUSDAddress != address(0), "cUSD=0");
        cUSD = IERC20(cUSDAddress);
    }

    // ======= Tạo offer (Lender) =======
    function createOffer(uint256 principal, uint256 interestBps, uint256 duration)
        external
        nonReentrant
        returns (uint256 id)
    {
        require(principal > 0, "principal=0");
        require(duration > 0, "duration=0");

        id = nextOfferId++;
        offers[id] = Offer({
            lender: msg.sender,
            borrower: address(0),
            principal: principal,
            interestBps: interestBps,
            duration: duration,
            startAt: 0,
            status: OfferStatus.Funded
        });

        bool ok = cUSD.transferFrom(msg.sender, address(this), principal);
        if (!ok) revert TransferFailed();

        emit OfferCreated(id, msg.sender, principal, interestBps, duration);
    }

    // ======= Hủy offer (Lender) =======
    function cancelOffer(uint256 id) external nonReentrant {
        Offer storage o = offers[id];
        if (msg.sender != o.lender) revert NotLender();
        if (o.status != OfferStatus.Funded) revert BadStatus();

        o.status = OfferStatus.Cancelled;
        bool ok = cUSD.transfer(o.lender, o.principal);
        if (!ok) revert TransferFailed();

        emit OfferCancelled(id);
    }

    // ======= Borrower nhận khoản vay =======
    function takeLoan(uint256 id) external nonReentrant {
        Offer storage o = offers[id];
        if (o.status != OfferStatus.Funded) revert BadStatus();

        o.status = OfferStatus.Taken;
        o.borrower = msg.sender;
        o.startAt = block.timestamp;

        bool ok = cUSD.transfer(msg.sender, o.principal);
        if (!ok) revert TransferFailed();

        emit LoanTaken(id, msg.sender);
    }

    // ======= Borrower hoàn trả =======
    function repay(uint256 id) external nonReentrant {
        Offer storage o = offers[id];
        if (msg.sender != o.borrower) revert NotBorrower();
        if (o.status != OfferStatus.Taken) revert BadStatus();

        uint256 repayAmt = _repayAmount(o);
        bool ok = cUSD.transferFrom(msg.sender, address(this), repayAmt);
        if (!ok) revert TransferFailed();

        o.status = OfferStatus.Repaid;
        emit LoanRepaid(id, repayAmt);
    }

    // ======= Lender rút tiền sau khi borrower repay =======
    function withdrawLender(uint256 id) external nonReentrant {
        Offer storage o = offers[id];
        if (msg.sender != o.lender) revert NotLender();
        if (o.status != OfferStatus.Repaid) revert BadStatus();

        uint256 repayAmt = _repayAmount(o);
        o.status = OfferStatus.Cancelled; // chốt trạng thái
        bool ok = cUSD.transfer(o.lender, repayAmt);
        if (!ok) revert TransferFailed();
    }

    // ======= Xem tổng số tiền borrower phải trả =======
    function repayAmount(uint256 id) external view returns (uint256) {
        return _repayAmount(offers[id]);
    }

    // ======= Hàm nội bộ tính gốc+lãi =======
    function _repayAmount(Offer storage o) internal view returns (uint256) {
        uint256 interest = (o.principal * o.interestBps) / 10_000;
        return o.principal + interest;
    }
}
