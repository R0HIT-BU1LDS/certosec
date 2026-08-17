# CertoSec V2

Blockchain-backed academic certificate issuance, storage and verification
platform. Institutions issue tamper-proof certificates on **Polygon Amoy**
(testnet); anyone can verify authenticity by scanning a QR code, entering a
certificate ID, or submitting a transaction hash.

```
┌─────────────────┐       ┌────────────────────────┐       ┌──────────────────────┐
│  Flutter App     │──HTTP─▶  Express / Supabase     │──────▶  Polygon Amoy        │
│  (students,      │       │  Backend API             │       │  CertoSecRegistry    │
│   verifiers,     │       │  - Auth (ES256 JWT)      │       │  (Solidity 0.8.24)  │
│   admins)        │       │  - Issuance + PDF        │       └──────────────────────┘
└─────────────────┘       │  - Verification engine   │
                           │  - Audit trail            │
                           └────────────────────────┘
```

## Repository layout

```
certosec-backend/   Node.js + Express API + ethers.js blockchain layer
certosec-frontend/  Flutter mobile & web app
```

## Quick start (backend)

```bash
cd certosec-backend
npm install
cp .env.example .env          # fill in Supabase + blockchain values
npm run dev                   # http://localhost:3000/api/v1
```

See [`certosec-backend/README.md`](certosec-backend/README.md) for full API
docs, environment variables, database setup and blockchain deployment guide.

## Quick start (frontend)

```bash
cd certosec-frontend
flutter pub get
flutter run                    # mobile / web
```

The Flutter app talks exclusively to the Express backend; it never contacts
Supabase or the blockchain directly.

## How verification works

1. **Issuance** -- Admin creates a certificate via the app. The backend
   computes a canonical SHA-256 hash of the certificate's immutable fields
   (student name, title, course, department, batch, issue date) and stores it
   in both the database **and** the on-chain contract.

2. **Verification** -- Anyone scans the QR code or enters a certificate UID.
   The backend looks up the database record, fetches the on-chain hash from
   the `CertoSecRegistry` contract, and compares both hashes. If they match
   and the certificate hasn't been revoked, it's authentic.

3. **Tamper detection** -- If someone modifies the database record, the stored
   hash diverges from the on-chain hash, and verification returns `TAMPERED`.
   If the on-chain record is missing, verification returns
   `BLOCKCHAIN_MISMATCH`.

## Blockchain

| Detail | Value |
| --- | --- |
| Network | Polygon Amoy (testnet, chainId 80002) |
| RPC | `https://polygon-amoy.drpc.org` |
| Contract | `CertoSecRegistry` (Solidity 0.8.24) |
| Explorer | <https://amoy.polygonscan.com> |

The contract is deployed and verified on Sourcify. Only the contract owner
(the deployer wallet) can issue certificates on-chain.

## Tech stack

| Layer | Technology |
| --- | --- |
| Frontend | Flutter, GoRouter, Provider |
| Backend | Node.js 22, Express, ethers.js v6 |
| Database | Supabase (PostgreSQL) |
| Auth | Supabase Auth (ES256 JWT, JWKS) |
| Storage | Supabase Storage (private PDF bucket) |
| Blockchain | Polygon Amoy, Solidity 0.8.24 |
| Testing | Jest, Supertest |

## Project status

- [x] Auth (login, logout, profile, forgot-password, admin provisioning)
- [x] Student CRUD (admin-only, paginated)
- [x] Certificate issuance (record + PDF + on-chain proof)
- [x] Certificate verification (UID, QR, transaction hash)
- [x] Dashboard stats
- [x] Blockchain integration (CertoSecRegistry deployed on Amoy)
- [x] Audit trail
- [ ] CI / CD pipeline
- [ ] Production deployment (Polygon mainnet)

## License

Proprietary -- all rights reserved.
