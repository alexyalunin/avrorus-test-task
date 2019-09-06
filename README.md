# Bounty0xStakingContract

[![Build Status](https://travis-ci.com/bounty0x/StakingContract.svg?branch=master)](https://travis-ci.com/bounty0x/StakingContract)

Staking contract based on Zeppelin Contracts

## Requirements

To run tests you need to install the following software:

- Truffle v5.0.35 (core: 5.0.35)
- Solidity v0.5.8 (solc-js)
- Node v12.5.0
- Web3.js v1.2.1

## Deployment

To deploy smart contracts to local network do the following steps:
1. Go to the smart contract folder and run truffle console:
```sh
$ cd avrorus-test-task
$ npm install
$ truffle develop
```
2. Inside truffle console, invoke "migrate" command to deploy contracts:
```sh
truffle> migrate
```


## How to test

Open the terminal and run the following commands:

```sh
$ cd avrorus-test-task
$ npm install
$ truffle test
```