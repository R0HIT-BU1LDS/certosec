// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title CertoSec Registry
/// @notice Immutable certificate registry for CertoSec V2.
///         Stores the SHA-256 canonical hash of each certificate under its UID.
///         The hash is the raw 32-byte digest (not a UTF-8 string), so the
///         backend sends it as 0x<64-hex>.
/// @dev   Deploy via Remix on Polygon Amoy (chainId 80002), then set
///        CONTRACT_ADDRESS in the backend .env.
contract CertoSecRegistry {
    struct Certificate {
        bytes32 uid;
        bytes32 hash;
        address issuer;
        uint256 issuedAt;
        bool exists;
    }

    mapping(bytes32 => Certificate) public certificates;

    address public owner;

    event CertificateIssued(
        bytes32 indexed uid,
        bytes32 hash,
        address indexed issuer,
        uint256 issuedAt
    );

    constructor() {
        owner = msg.sender;
    }

    /// @notice Records a certificate on-chain. Only callable by the owner.
    /// @param uid  UTF-8 bytes32 of the certificate UID (e.g. "CERT-2026-000001")
    /// @param hash Raw SHA-256 digest of the canonical certificate data
    function issueCertificate(bytes32 uid, bytes32 hash) external returns (bool) {
        require(uid != bytes32(0), "CertoSecRegistry: uid cannot be zero");
        require(hash != bytes32(0), "CertoSecRegistry: hash cannot be zero");
        require(!certificates[uid].exists, "CertoSecRegistry: certificate already issued");
        require(msg.sender == owner, "CertoSecRegistry: only owner can issue");

        certificates[uid] = Certificate(uid, hash, msg.sender, block.timestamp, true);
        emit CertificateIssued(uid, hash, msg.sender, block.timestamp);
        return true;
    }

    /// @notice Returns the full on-chain record for a UID.
    function getCertificate(bytes32 uid)
        external
        view
        returns (
            bytes32 uid_,
            bytes32 hash_,
            address issuer_,
            uint256 issuedAt_,
            bool exists_
        )
    {
        Certificate storage c = certificates[uid];
        return (c.uid, c.hash, c.issuer, c.issuedAt, c.exists);
    }

    /// @notice True when a certificate exists for the UID.
    function isIssued(bytes32 uid) external view returns (bool) {
        return certificates[uid].exists;
    }

    /// @notice On-chain tamper check: does the stored hash equal the given hash?
    function verifyCertificate(bytes32 uid, bytes32 hash) external view returns (bool) {
        Certificate storage c = certificates[uid];
        return c.exists && c.hash == hash;
    }

    /// @notice Lets the owner transfer ownership.
    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "CertoSecRegistry: only owner");
        require(newOwner != address(0), "CertoSecRegistry: invalid owner");
        owner = newOwner;
    }
}
