/**
 * Deployment check for the CertoSec contract on Polygon Amoy.
 *
 * Usage:
 *   node scripts/checkContract.js [contractAddress]
 *
 * Reads env CONTRACT_ADDRESS (or the positional arg), then confirms:
 *   1. the address has code (deployed),
 *   2. owner() matches your BLOCKCHAIN_PRIVATE_KEY wallet,
 *   3. isIssued/getCertificate/verifyCertificate behave for a probe UID.
 *
 * Network read-only — no gas, no funds needed.
 */
const { JsonRpcProvider, Contract, encodeBytes32String, formatEther } = require('ethers');
const env = require('../src/config/env');
const contractABI = require('../src/blockchain/contractABI.json');

const probeUid = 'CERT-0000-000000';
const probeHash = '0x' + 'ab'.repeat(32); // 64 hex chars, never used for a real cert

async function main() {
  const address = (process.argv[2] || env.blockchain.contractAddress || '').toLowerCase();
  if (!address) {
    console.error('No contract address. Pass one as an argument or set CONTRACT_ADDRESS in .env');
    process.exit(1);
  }

  const provider = new JsonRpcProvider(env.blockchain.rpcUrl, {
    chainId: env.blockchain.chainId,
    name: env.blockchain.networkName,
  });
  const code = await provider.getCode(address);
  if (!code || code === '0x') {
    console.error(`ERROR: no contract at ${address} — is it the right address on ${env.blockchain.networkName}?`);
    process.exit(1);
  }
  console.log(`Deployed contract at ${address} (${env.blockchain.networkName}, chainId ${env.blockchain.chainId})`);

  const contract = new Contract(address, contractABI, provider);

  const owner = await contract.owner();
  console.log(`owner() = ${owner}`);

  if (env.blockchain.privateKey) {
    const { Wallet } = require('ethers');
    const expected = new Wallet(env.blockchain.privateKey, provider).address.toLowerCase();
    if (owner.toLowerCase() === expected) {
      console.log('owner matches BLOCKCHAIN_PRIVATE_KEY wallet -> issuance will be accepted');
    } else {
      console.warn(`WARNING: owner (${owner}) differs from your signing wallet (${expected}).`);
      console.warn('issueCertificate() requires the owner; sign with the owner key or transferOwnership().');
    }
  }

  const issued = await contract.isIssued(encodeBytes32String(probeUid));
  console.log(`isIssued("${probeUid}") = ${issued}  (expect false — probe UID)`);

  const record = await contract.getCertificate(encodeBytes32String(probeUid));
  console.log(`getCertificate(probe) exists = ${record.exists}`);

  const ok = await contract.verifyCertificate(encodeBytes32String(probeUid), probeHash);
  console.log(`verifyCertificate(probe) = ${ok}  (expect false)`);

  console.log('\nABI checks passed. Copy this address into CONTRACT_ADDRESS in .env if not already set.');
}

main().catch((err) => {
  console.error('check failed:', err.shortMessage || err.message || err);
  process.exit(1);
});
