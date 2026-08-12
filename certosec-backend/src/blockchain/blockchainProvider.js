const { JsonRpcProvider, Wallet, Contract, encodeBytes32String } = require('ethers');
const env = require('../config/env');
const contractABI = require('./contractABI.json');
const ApiError = require('../utils/ApiError');
const logger = require('../utils/logger');

let provider = null;
let signer = null;
let contract = null;

function assertConfigured() {
  if (!env.blockchain.privateKey) {
    throw new ApiError(
      503,
      'BLOCKCHAIN_NOT_CONFIGURED',
      'Blockchain signing is not configured on the server.',
    );
  }
  if (!env.blockchain.contractAddress) {
    throw new ApiError(
      503,
      'BLOCKCHAIN_NOT_CONFIGURED',
      'The certificate contract address is not configured.',
    );
  }
}

function getProvider() {
  if (!provider) {
    provider = new JsonRpcProvider(env.blockchain.rpcUrl, {
      chainId: env.blockchain.chainId,
      name: env.blockchain.networkName,
    });
  }
  return provider;
}

function getSigner() {
  assertConfigured();
  if (!signer) {
    signer = new Wallet(env.blockchain.privateKey, getProvider());
  }
  return signer;
}

function getContract() {
  assertConfigured();
  if (!contract) {
    contract = new Contract(env.blockchain.contractAddress, contractABI, getSigner());
  }
  return contract;
}

function reset() {
  provider = null;
  signer = null;
  contract = null;
}

function toBytes32(value) {
  return encodeBytes32String(value);
}

module.exports = { getProvider, getSigner, getContract, toBytes32, reset };
