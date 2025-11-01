# Celo P2P Lending DApp
> **Decentralized Peer-to-Peer Lending Platform with Collateralized Local Currency Loans**

This project is a **smart-contract-based lending dApp** built on the **Celo blockchain**, enabling borrowers to request loans using **stable tokens (like cUSD/cEUR/cREAL)** and deposit **collateral tokens** to secure them.  
Lenders can fund loan requests directly, earning interest while minimizing risk through over-collateralization.

---

## Project Overview

### Core Idea
A **P2P lending protocol** where:
- Borrowers request loans in local stable tokens.
- They deposit ERC-20 collateral (over-collateralized, e.g. 150%).
- Lenders fund loans and earn fixed interest.
- If the borrower repays before due date → collateral is returned.  
  Otherwise, the lender can **liquidate** the collateral.

### Goals
- Promote **financial inclusion** using Celo’s local stablecoins.
- Build a **trust-minimized**, transparent loan system.
- Demonstrate **smart contract deployment on the Celo testnet (Sepolia / Alfajores)** using **Remix IDE**.

---

## Features

| Role | Action | Description |
|------|---------|-------------|
| Borrower | `requestLoan()` | Create loan request with collateral & terms |
| Borrower | `cancelUnfunded()` | Cancel loan before lender funds it |
| Lender | `fund()` | Fund a borrower’s loan |
| Borrower | `repay()` | Repay loan + interest before due date |
| Lender | `liquidate()` | Claim collateral if borrower defaults |
| Public | `getLoan()` | View loan details |

All operations are fully **on-chain** and event-driven (no backend required).

---

## Smart Contract

### File
`contracts/CollateralizedP2PLending.sol`

### Tech Stack
- Solidity `^0.8.19`
- OpenZeppelin libraries (`IERC20`, `ReentrancyGuard`)
- EVM-compatible with **Celo**
- Deployed via **Remix + MetaMask**

### Key Parameters
| Variable | Type | Description |
|-----------|------|-------------|
| `principal` | uint256 | Amount of loan requested (in loanToken) |
| `collateral` | uint256 | Collateral amount (in collateralToken) |
| `interest` | uint256 | Flat interest (loanToken units) |
| `dueTimestamp` | uint256 | UNIX timestamp for loan expiry |
| `minCollateralRatioBps` | uint256 | e.g. 15000 = 150% |

---

## Deployment Guide

### Prerequisites
- [Remix IDE](https://remix.ethereum.org)
- [MetaMask](https://metamask.io/)
- Celo testnet (Sepolia or Alfajores) configured  
  ```text
  Network Name: Celo Sepolia Testnet
  RPC URL: https://rpc.sepolia.celo-testnet.org
  Chain ID: 11142220
  Currency Symbol: CELO
  Block Explorer: https://explorer.sepolia.celo-testnet.org
