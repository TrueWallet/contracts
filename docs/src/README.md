# <h1 align="center"> TrueWallet Contracts </h1>

<h3 align="center"> This repository contains the smart contract suite used in TrueWallet project </h3>
<br>

![Github Actions](https://github.com/devanonon/hardhat-foundry-template/workflows/test/badge.svg)

## Features
+ Support [ERC-4337: Account Abstraction](https://eips.ethereum.org/EIPS/eip-4337)
+ Social Recovery with Guardians
+ Upgradability: The smart contract wallet can be upgraded in a secure way to add new features or fix vulnerabilities in the future


## Getting Started

### Install Foundry and Forge: [installation guide](https://book.getfoundry.sh/getting-started/installation)

### Setup:
```bash
git clone <repo_link>
```
### Install dependencies:
```bash
forge install
```
### Compile contracts:
```bash
yarn build

```
### Run unit tests:
```bash
yarn test
```
### Add required .env variables:
```bash
cp .env.example .env
```
### Run fork tests:
```bash
yarn test::fork
```



<!-- ACKNOWLEDGMENTS -->
## Acknowledgments
* <a href='https://github.com/eth-infinitism/account-abstraction'>eth-infinitism/account-abstraction</a>
* <a href='https://eips.ethereum.org/EIPS/eip-4337'>EIP-4337: Account Abstraction via Entry Point Contract specification </a>
