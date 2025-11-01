// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CollateralizedP2PLending is ReentrancyGuard {
    struct Loan {
        address borrower;
        address lender;
        IERC20 loanToken;        // e.g., cUSD/cEUR/cREAL (or any ERC20)
        IERC20 collateralToken;  // any ERC20 used as collateral
        uint256 principal;       // amount of loanToken requested
        uint256 collateral;      // amount of collateralToken posted
        uint256 interest;        // flat interest (loanToken units)
        uint256 dueTimestamp;    // unix ts
        uint256 minCollateralRatioBps; // e.g., 15000 = 150%
        bool    funded;
        bool    repaid;
        bool    liquidated;
    }

    uint256 public loanCount;
    mapping(uint256 => Loan) public loans;

    event LoanRequested(
        uint256 indexed loanId,
        address indexed borrower,
        address loanToken,
        address collateralToken,
        uint256 principal,
        uint256 collateral,
        uint256 interest,
        uint256 dueTimestamp,
        uint256 minCollateralRatioBps
    );
    event LoanFunded(uint256 indexed loanId, address indexed lender);
    event LoanRepaid(uint256 indexed loanId);
    event LoanLiquidated(uint256 indexed loanId);

    error NotBorrower();
    error NotLender();
    error AlreadyFunded();
    error NotFunded();
    error AlreadyClosed();
    error BadParams();
    error CollateralTooLow();

    function requestLoan(
        address loanToken,
        address collateralToken,
        uint256 principal,
        uint256 collateral,
        uint256 interest,
        uint256 dueTimestamp,
        uint256 minCollateralRatioBps
    ) external nonReentrant returns (uint256 id) {
        if (
            loanToken == address(0) ||
            collateralToken == address(0) ||
            principal == 0 ||
            collateral == 0 ||
            dueTimestamp <= block.timestamp ||
            minCollateralRatioBps < 10000 // must be >= 100%
        ) revert BadParams();

        // Simple on-chain check: collateral >= principal * ratio
        // (No oracle here—devs can later plug a price feed.)
        if (collateral * 10000 < principal * minCollateralRatioBps) revert CollateralTooLow();

        id = ++loanCount;
        loans[id] = Loan({
            borrower: msg.sender,
            lender: address(0),
            loanToken: IERC20(loanToken),
            collateralToken: IERC20(collateralToken),
            principal: principal,
            collateral: collateral,
            interest: interest,
            dueTimestamp: dueTimestamp,
            minCollateralRatioBps: minCollateralRatioBps,
            funded: false,
            repaid: false,
            liquidated: false
        });

        // Pull collateral from borrower
        require(loans[id].collateralToken.transferFrom(msg.sender, address(this), collateral), "collateral xfer failed");

        emit LoanRequested(
            id, msg.sender, loanToken, collateralToken,
            principal, collateral, interest, dueTimestamp, minCollateralRatioBps
        );
    }

    function cancelUnfunded(uint256 id) external nonReentrant {
        Loan storage L = loans[id];
        if (L.borrower != msg.sender) revert NotBorrower();
        if (L.funded) revert AlreadyFunded();
        if (L.repaid || L.liquidated) revert AlreadyClosed();

        // Return collateral
        require(L.collateralToken.transfer(L.borrower, L.collateral), "return collateral failed");
        delete loans[id]; // save storage
    }

    function fund(uint256 id) external nonReentrant {
        Loan storage L = loans[id];
        if (L.funded) revert AlreadyFunded();
        if (L.repaid || L.liquidated) revert AlreadyClosed();

        L.lender = msg.sender;
        L.funded = true;

        // Transfer principal to borrower
        require(L.loanToken.transferFrom(msg.sender, L.borrower, L.principal), "principal xfer failed");

        emit LoanFunded(id, msg.sender);
    }

    function repay(uint256 id) external nonReentrant {
        Loan storage L = loans[id];
        if (!L.funded) revert NotFunded();
        if (L.borrower != msg.sender) revert NotBorrower();
        if (L.repaid || L.liquidated) revert AlreadyClosed();

        // Transfer principal + interest from borrower to lender
        uint256 pay = L.principal + L.interest;
        require(L.loanToken.transferFrom(msg.sender, L.lender, pay), "repay xfer failed");

        L.repaid = true;

        // Return collateral to borrower
        require(L.collateralToken.transfer(L.borrower, L.collateral), "collateral return failed");

        emit LoanRepaid(id);
    }

    function liquidate(uint256 id) external nonReentrant {
        Loan storage L = loans[id];
        if (!L.funded) revert NotFunded();
        if (L.repaid || L.liquidated) revert AlreadyClosed();
        if (block.timestamp <= L.dueTimestamp) revert BadParams(); // too early

        L.liquidated = true;

        // Send collateral to lender
        require(L.collateralToken.transfer(L.lender, L.collateral), "collateral to lender failed");

        emit LoanLiquidated(id);
    }

    // Helpers
    function getLoan(uint256 id) external view returns (Loan memory) {
        return loans[id];
    }
}
