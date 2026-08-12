const { getContract, getSigner, getProvider, toBytes32 } = require('./blockchainProvider');
const env = require('../config/env');
const logger = require('../utils/logger');

/**
 * BlockchainService — every on-chain interaction for certificates goes through
 * here. Express controllers never talk to ethers directly.
 *
 * The bundled contractABI.json describes the expected CertoSec interface:
 *   issueCertificate(bytes32 uid, bytes32 hash)
 *   getCertificate(bytes32 uid) -> (bytes32 uid, bytes32 hash, address issuer,
 *                                    uint256 issuedAt, bool exists)
 *   isIssued(bytes32 uid) -> bool
 *   verifyCertificate(bytes32 uid, bytes32 hash) -> bool
 *
 * IMPORTANT: replace contractABI.json with the ABI from your Remix-deployed
 * contract (and set CONTRACT_ADDRESS) before live issuance. The contract must
 * expose the functions above, otherwise these calls will revert.
 */
async function issueCertificate({ uid, hash }) {
  const contract = getContract();
  const signer = getSigner();
  const provider = getProvider();

  const tx = await contract.issueCertificate(toBytes32(uid), toBytes32(hash));
  logger.info('Certificate issuance tx submitted', {
    uid,
    txHash: tx.hash,
    network: env.blockchain.networkName,
  });

  const receipt = await tx.wait(env.blockchain.confirmations);
  const block = await provider.getBlock(receipt.blockNumber);

  return {
    transactionHash: receipt.hash,
    blockNumber: Number(receipt.blockNumber),
    blockTimestamp: block ? new Date(Number(block.timestamp) * 1000).toISOString() : null,
    issuerAddress: await signer.getAddress(),
    contractAddress: env.blockchain.contractAddress,
    network: env.blockchain.networkName,
  };
}

/** Reads the on-chain record for a UID (null-safe: may throw if contract errors). */
async function getCertificate(uid) {
  const contract = getContract();
  const result = await contract.getCertificate(toBytes32(uid));
  return {
    uid: result.uid,
    hash: result.hash,
    issuer: result.issuer,
    issuedAt: result.issuedAt,
    exists: Boolean(result.exists),
  };
}

async function isIssued(uid) {
  const contract = getContract();
  return Boolean(await contract.isIssued(toBytes32(uid)));
}

/** On-chain comparison of the stored hash against the canonical hash. */
async function verifyCertificate(uid, hash) {
  const contract = getContract();
  return Boolean(await contract.verifyCertificate(toBytes32(uid), toBytes32(hash)));
}

/** Returns the raw transaction, or null when it does not exist on-chain. */
async function getTransaction(transactionHash) {
  const provider = getProvider();
  const tx = await provider.getTransaction(transactionHash);
  if (!tx) return null;
  const receipt = await provider.getTransactionReceipt(transactionHash);
  return {
    hash: tx.hash,
    to: tx.to ? tx.to.toLowerCase() : null,
    from: tx.from.toLowerCase(),
    blockNumber: tx.blockNumber != null ? Number(tx.blockNumber) : null,
    status: receipt ? (receipt.status === 1 ? 'success' : 'reverted') : 'pending',
  };
}

module.exports = {
  issueCertificate,
  getCertificate,
  isIssued,
  verifyCertificate,
  getTransaction,
};
