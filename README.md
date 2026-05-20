# ApexFi Protocol

## Project Overview
**ApexFi Protocol** is a full-stack Decentralized Finance (DeFi) Super-App developed as the Capstone Project for the **Blockchain Technologies 2** course at Astana IT University. 

This production-grade ecosystem integrates multiple DeFi primitives—decentralized trading, algorithmic lending, and yield generation—into a single platform. The protocol is entirely community-driven via a DAO, relies on decentralized oracles for secure pricing, and is optimized for Layer 2 scaling solutions.

## Core Protocol Ecosystem

### 1. Automated Market Maker (AMM) & Factory
The decentralized exchange layer allows for permissionless token swaps.
* **Constant Product AMM:** Implements the classic $x \cdot y = k$ invariant with a standard 0.3% swap fee distributed to liquidity providers.
* **Optimized Factory:** Utilizes the `CREATE2` opcode and low-level **Yul (Inline Assembly)** to dynamically and deterministically deploy unique trading pairs with maximum gas efficiency.

### 2. Lending Protocol
A decentralized money market for borrowing and lending digital assets.
* Users can supply assets to earn dynamic interest or borrow against their collateral.
* Implements robust health factor calculations and a liquidation mechanism to ensure protocol solvency during market volatility.

### 3. ERC-4626 Yield Vault
A standardized, tokenized vault system for passive yield generation.
* Fully compliant with the **ERC-4626** standard.
* Auto-compounds protocol fees and lending interest, issuing Vault Shares to depositors that mathematically appreciate in value over time.

### 4. Decentralized Governance (DAO)
The protocol features no centralized admin keys. All parameters (fees, new collateral types, logic upgrades) are managed by the community.
* Built on the `Governor` and `TimelockController` architecture.
* Utilizes `ERC20Votes` with a strict snapshot mechanism to mathematically eliminate flash-loan voting manipulation.
* Enforces a mandatory time-delay (Timelock) on all approved proposals to guarantee user safety.

### 5. Decentralized Oracles (Chainlink)
* Integrates **Chainlink Price Feeds** to fetch real-time, tamper-proof USD valuations for lending collateral and AMM routing.
* Includes strict staleness checks and sequencer uptime validations for Layer 2 security.

### 6. Data Indexing (The Graph)
* Replaces inefficient direct blockchain queries with a custom **Subgraph**.
* Indexes critical protocol events (Swaps, Liquidations, Votes) into a GraphQL API, providing a seamless and lightning-fast frontend experience.

## Technology Stack & Infrastructure
* **Smart Contracts:** Solidity, Yul (Assembly), OpenZeppelin Contracts.
* **Development & QA:** Foundry suite (Forge, Cast, Anvil) with extensive Unit, Fuzz, and Invariant testing ($\ge$ 90% coverage).
* **Security:** CEI (Checks-Effects-Interactions) patterns, ReentrancyGuards, SafeERC20, and continuous static analysis via Slither.
* **Frontend:** React, Ethers.js / Wagmi for Web3 wallet integration.
* **Deployment:** Layer 2 Networks (Arbitrum Sepolia / Optimism Sepolia) for high throughput and reduced transaction costs.
