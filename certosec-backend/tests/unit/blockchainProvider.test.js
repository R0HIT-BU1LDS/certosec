const { toBytes32, toHashBytes32 } = require('../../src/blockchain/blockchainProvider');
const { encodeBytes32String } = require('ethers');

describe('blockchainProvider encoders', () => {
  describe('toBytes32', () => {
    test('UTF-8 encodes a certificate UID', () => {
      expect(toBytes32('CERT-2026-000001')).toBe(encodeBytes32String('CERT-2026-000001'));
    });

    test('pads short strings to exactly 32 bytes', () => {
      expect(toBytes32('CERT-2026-000001')).toMatch(/^0x[0-9a-f]{64}$/);
    });
  });

  describe('toHashBytes32', () => {
    test('converts a lowercase 64-hex digest to its raw bytes32 value', () => {
      const hash = 'a'.repeat(64);
      expect(toHashBytes32(hash)).toBe(`0x${hash}`);
    });

    test('accepts an 0x-prefixed digest and normalizes it', () => {
      const hash = 'b'.repeat(64);
      expect(toHashBytes32(`0x${hash.toUpperCase()}`)).toBe(`0x${hash}`);
    });

    test('rejects a hash that is not a valid 64-hex digest', () => {
      expect(() => toHashBytes32('not-a-hash')).toThrow();
      expect(() => toHashBytes32('a'.repeat(63))).toThrow();
      expect(() => toHashBytes32('zz'.repeat(32))).toThrow();
    });

    test('rejects a missing hash', () => {
      expect(() => toHashBytes32('')).toThrow();
      expect(() => toHashBytes32(undefined)).toThrow();
    });
  });
});
