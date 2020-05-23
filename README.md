[![#ubuntu 18.04](https://img.shields.io/badge/ubuntu-v18.04-orange?style=plastic)](https://ubuntu.com/download/desktop)
[![#npm 13.13.0](https://img.shields.io/badge/npm-v13.13.0-blue?style=plastic)](https://github.com/nvm-sh/nvm#installation-and-update)
[![#built_with_Truffle](https://img.shields.io/badge/built%20with-Truffle-blueviolet?style=plastic)](https://www.trufflesuite.com/)
[![#solc 0.6.8](https://img.shields.io/badge/solc-v0.6.8-brown?style=plastic)](https://github.com/ethereum/solidity/releases/tag/v0.6.8)
[![#testnet kovan](https://img.shields.io/badge/testnet-Kovan-purple?style=plastic&logo=Ethereum)]()

# InsigniaDAO

> Non-transferable Badges for Maker Ecosystem Activity, [issue #537](https://github.com/makerdao/community/issues/537)


# Mentors
- Mariano Conti, [@nanexcool](https://github.com/nanexcool)
- Josh Crites, [@critesjosh](https://github.com/critesjosh)
- Yannis Stamelakos, [@i-stam](https://github.com/i-stam)
- Dror Tirosh (OpenGSN), [@drortirosh](https://github.com/drortirosh)

Project Setup
============

Clone this GitHub repository.

# Steps to compile and deploy

  - Local dependencies:
    - Truffle
    - Ganache CLI
    - OpenZeppelin Contracts v3.0.1
    - OpenGSN Contracts v0.9.0
    - Truffle-Flattener
    ```
    $ npm i
    ```
  - Global dependencies:
    - MythX CLI (optional):
    ```sh
    $ git clone git://github.com/dmuhs/mythx-cli
    $ sudo python setup.py install
    ```
## Running the project with local test network (ganache-cli)

   - Start ganache-cli with the following command:
     ```sh
     $ ganache-cli
     ```
   - Compile the smart contract using Truffle with the following command:
     ```sh
     $ truffle compile
     ```
   - Deploy the smart contracts using Truffle & Ganache with the following command:
     ```sh
     $ truffle migrate
     ```
   - Test the smart contracts using Truffle & Ganache with the following command:
     ```sh
     $ truffle test
     ```
   - Analyze the smart contracts using MythX CLI with the following command (optional):
     ```sh
     $ mythx analyze
     ```
## MythX CLI Report
Contract | Line | SWC Title | Severity | Short Description 
--- | --- | --- | --- | ---
InsigniaDAO.sol | 80 | Timestamp Dependence | Low | A control flow decision is made based on The block.timestamp environment variable.

## Deploy on Kovan Testnet
 - Get an Ethereum Account on Metamask.
 - On the landing page, click “Get Chrome Extension.”
 - Create a .secret file cointaining the menomic.
 - Get some test ether from a [Kovan's faucet](https://faucet.kovan.network/).
 - Signup [Infura](https://infura.io/).
 - Create new project.
 - Copy the rinkeby URL into truffle-config.js.
 - Uncomment the following lines in truffle-config.js:
   ```
   // const HDWalletProvider = require("@truffle/hdwallet-provider");
   // const infuraKey = '...';
   // const infuraURL = 'https://kovan.infura.io/...';

   // const fs = require('fs');
   // const mnemonic = fs.readFileSync(".secret").toString().trim();
   ```
 - Install Truffle HD Wallet Provider:
   ```sh
   $ npm install @truffle/hdwallet-provider
   ```
 - Deploy the smart contract using Truffle & Infura with the following command:
   ```sh
   $ truffle migrate --network kovan
   ```

## Project deployed on Kovan
[InsigniaDAO.sol (OpenGSN)](https://kovan.etherscan.io/address/0x098798b4aF578F9c0d933e114576d32550b24C75)  
[BadgeFactory.sol (OpenGSN)](https://kovan.etherscan.io/address/0x3Aa897f4fE6306a9C047F30b7B62555b20F63092)  
[BadgePaymaster.sol (OpenGSN)](https://kovan.etherscan.io/address/0x7Db6a577bD62e25b4f9F6cA684780DBeC356ca72)

## Inspiration & References

- [open-proofs](https://github.com/rrecuero/open-proofs)
- [ERC1238](https://github.com/ethereum/EIPs/issues/1238)
- [ERC721](https://eips.ethereum.org/EIPS/eip-721)
- [POAP](https://www.poap.xyz/)
- [MakerDAO](https://makerdao.com/en/)
- [Chai](https://chai.money/about.html)

## About

Project created by [Nazzareno Massari](https://www.nazzarenomassari.com), Scott Herren in collaboration with Bryan Flynn.  
Team MetaBadges from HackMoney ETHGlobal Virtual Hackathon.
