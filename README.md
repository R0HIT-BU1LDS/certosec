# CertoSec V2

**Blockchain-backed academic certificate verification platform.**

CertoSec lets universities and institutions issue tamper-proof academic
certificates on the blockchain. Once issued, certificates can be independently
verified by anyone — employers, other institutions, or anyone with the QR
code — without trusting the issuing organization's database.

The problem CertoSec solves: traditional digital certificates (PDFs, database
records) can be forged, edited, or deleted. By anchoring each certificate's
identity hash on-chain, verification becomes a matter of checking an immutable
public ledger rather than asking the issuing institution.

---

## Table of contents

- [How it works](#how-it-works)
- [User roles](#user-roles)
- [Architecture](#architecture)
- [Technology stack](#technology-stack)
- [Repository structure](#repository-structure)
- [Getting started](#getting-started)
- [Database](#database)
- [Blockchain contract](#blockchain-contract)
- [API overview](#api-overview)
- [Security model](#security-model)
- [Testing](#testing)
- [Project status](#project-status)

---

## How it works

### Issuance

1. An **admin** logs into the Flutter app and registers a student.
2. The admin creates a certificate for that student (selecting title, course,
   department, batch).
3. The backend generates a unique ID (`CERT-2026-000001`) and computes a
   **canonical SHA-256 hash** of the certificate's immutable fields:

   ```
   { version, certificateUid, studentUid, studentName, title,
     course, department, batch, issueDate }
   ```

4. The hash is stored in two places simultaneously:
   - The **Supabase database** (with the full certificate record)
   - The **CertoSecRegistry smart contract** on Polygon Amoy (as a `bytes32`
     value locked to the certificate's UID)
5. If blockchain submission fails, the record stays `pending` and can be
   retried — the certificate data is never lost.

### Verification

Anyone can verify a certificate without needing an account:

1. **Scan the QR code** or **enter a certificate UID** (`CERT-2026-000001`)
   or **submit a transaction hash** (`0x...`).
2. The backend fetches the certificate from the database and the on-chain
   record from the smart contract.
3. It compares three things:
   - Does the on-chain record exist? (`BLOCKCHAIN_MISMATCH` if not)
   - Does the on-chain hash match the database hash? (`TAMPERED` if not)
   - Does a fresh recomputation of the canonical hash match what's stored?
     (`TAMPERED` if the database record was altered after issuance)
4. If all checks pass: `VALID` — the certificate is authentic and untampered.

### Tamper detection

| Scenario | Verdict | Why |
| --- | --- | --- |
| Database record edited after issuance | `TAMPERED` | Recomputed hash diverges from stored hash |
| Database record edited + stored hash updated | `TAMPERED` | Stored hash diverges from on-chain hash |
| No on-chain record found | `BLOCKCHAIN_MISMATCH` | Certificate was never written to chain or RPC is down |
| Certificate revoked by admin | `INVALID` | Status is explicitly `revoked` |
| Certificate not yet written to chain | `INVALID` | Status is `pending` |

---

## User roles

| Role | Access | Provisioning |
| --- | --- | --- |
| **admin** | Full access: students, certificates, issuance, dashboard | The email in `ADMIN_EMAIL` gets admin on first login |
| **verifier** | Public verification endpoints (no login required) | N/A — verification is public |
| **authenticated user** | View own profile, logout | Anyone who registers via Supabase Auth |

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           Flutter App                                    │
│  ┌─────────┐  ┌─────────────┐  ┌───────────────┐  ┌────────────────┐  │
│  │  Login   │  │  Dashboard  │  │  Certificates │  │  Verification  │  │
│  │  (auth)  │  │  (stats)    │  │  (issue, list)│  │  (QR, UID)     │  │
│  └────┬─────┘  └──────┬──────┘  └───────┬───────┘  └───────┬────────┘  │
│       └───────────────┼─────────────────┼──────────────────┘            │
│                       │  HTTP (REST)    │                                │
└───────────────────────┼─────────────────┼────────────────────────────────┘
                        ▼                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                      Express Backend API                                 │
│                                                                          │
│  ┌──────────────┐  ┌─────────────────┐  ┌────────────────────────────┐  │
│  │  Auth (ES256 │  │  Certificate     │  │  Verification Engine       │  │
│  │  JWT + JWKS) │  │  Service         │  │  (hash comparison,         │  │
│  └──────┬───────┘  │  (issue + PDF)   │  │   on-chain lookup)         │  │
│         │          └────────┬─────────┘  └───────────┬────────────────┘  │
│         │                   │                       │                    │
│  ┌──────▼───────┐  ┌───────▼──────────┐  ┌─────────▼────────────────┐  │
│  │  Supabase    │  │  Supabase        │  │  Polygon Amoy            │  │
│  │  Auth        │  │  Storage         │  │  CertoSecRegistry        │  │
│  │  (users)     │  │  (PDFs)          │  │  (on-chain hashes)       │  │
│  └──────────────┘  └──────────────────┘  └──────────────────────────┘  │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │  Supabase PostgreSQL                                             │   │
│  │  profiles | students | certificates | audit_logs                 │   │
│  └──────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────┘
```

**Key design decisions:**

- The backend is the **only** component that talks to Supabase and the
  blockchain. The Flutter app never contacts either directly.
- Auth uses **ES256 JWTs verified via JWKS** — no shared secret to manage.
- PDFs are stored in a **private** Supabase Storage bucket and served via
  short-lived signed URLs.
- Every certificate mutation is recorded in an **audit log**.
- Rate limiting is applied to verification (30/min) and login endpoints.

---

## Technology stack

| Component | Technology | Purpose |
| --- | --- | --- |
| Frontend | Flutter 3.x, GoRouter, Provider | Mobile + web app |
| Backend API | Node.js 22, Express 4.x | REST API server |
| Auth | Supabase Auth, jose (ES256 JWKS) | User authentication |
| Database | Supabase (PostgreSQL 15) | Persistent storage |
| File Storage | Supabase Storage | Private PDF bucket |
| Blockchain | ethers.js v6, Solidity 0.8.24 | On-chain certificate registry |
| Network | Polygon Amoy (testnet, chainId 80002) | Low-cost test chain |
| Testing | Jest, Supertest | Unit + integration tests |
| Tooling | nodemon, ESLint | Development workflow |

---

## Repository structure

```
certosec/
├── README.md                          # This file
│
├── certosec-backend/                  # Express + Supabase + ethers.js
│   ├── contracts/
│   │   └── CertoSecRegistry.sol       # Solidity smart contract source
│   ├── scripts/
│   │   └── checkContract.js           # Post-deployment verification
│   ├── src/
│   │   ├── app.js                     # Express app setup
│   │   ├── server.js                  # Entrypoint
│   │   ├── config/                    # env.js (typed env), supabase.js
│   │   ├── blockchain/
│   │   │   ├── blockchainProvider.js  # ethers provider / wallet / contract
│   │   │   ├── blockchainService.js   # On-chain calls (issue, read, verify)
│   │   │   └── contractABI.json       # ABI matching CertoSecRegistry.sol
│   │   ├── database/
│   │   │   └── schema.sql             # Run once in Supabase SQL editor
│   │   ├── services/
│   │   │   ├── hashService.js         # Canonical SHA-256 (source of truth)
│   │   │   ├── verificationService.js # Single verification engine
│   │   │   ├── certificateService.js  # Issuance pipeline
│   │   │   ├── studentService.js      # Student CRUD
│   │   │   ├── authService.js         # Login, profile, password reset
│   │   │   ├── storageService.js      # PDF validation, upload, signed URLs
│   │   │   ├── auditService.js        # Audit trail
│   │   │   └── index.js              # Dependency container
│   │   ├── models/                    # snake_case -> camelCase serializers
│   │   ├── repositories/              # Supabase data access layer
│   │   ├── controllers/               # HTTP handlers
│   │   ├── validators/                # express-validator chains
│   │   ├── routes/                    # Mounted under /api/v1
│   │   ├── middleware/                # Auth, RBAC, rate limits, errors
│   │   └── utils/                     # ApiError, logger, uidGenerator
│   ├── tests/
│   │   ├── unit/                      # 5 test suites
│   │   └── integration/               # Route + error handling
│   ├── .env.example                   # Environment template
│   ├── package.json
│   └── README.md                      # Full backend + API docs
│
└── certosec-frontend/                 # Flutter app
    ├── lib/
    │   ├── main.dart                  # App entrypoint
    │   ├── core/
    │   │   ├── config/                # API base URL, app settings
    │   │   ├── routes/                # GoRouter route definitions
    │   │   └── theme/                 # Material theme
    │   ├── models/                    # Data models (student, certificate)
    │   ├── providers/                 # State management (6 providers)
    │   ├── repositories/              # HTTP client layer
    │   ├── screens/
    │   │   ├── login/                 # Authentication
    │   │   ├── home/                  # Landing / role-based home
    │   │   ├── dashboard/             # Admin stats
    │   │   ├── students/              # Student CRUD screens
    │   │   ├── certificates/          # Issue, list, view, PDF
    │   │   ├── verification/          # QR scan, UID entry, results
    │   │   ├── profile/               # User profile
    │   │   ├── settings/              # App settings
    │   │   └── splash/                # Loading screen
    │   └── services/                  # HTTP, auth, storage services
    ├── pubspec.yaml
    └── README.md
```

---

## Getting started

### Prerequisites

- Node.js >= 18
- Flutter SDK >= 3.10
- A Supabase project (free tier works)
- MetaMask (for blockchain deployment)

### Backend

```bash
cd certosec-backend
npm install
cp .env.example .env     # fill in your values
npm run dev              # http://localhost:3000/api/v1
```

See [`certosec-backend/README.md`](certosec-backend/README.md) for the
full environment variable table and API documentation.

### Frontend

```bash
cd certosec-frontend
flutter pub get
flutter run
```

The Flutter app points at the Express backend. No Supabase or blockchain
configuration is needed in the Flutter code itself.

---

## Database

Run `certosec-backend/src/database/schema.sql` in the Supabase SQL editor.

### Tables

| Table | Purpose |
| --- | --- |
| `profiles` | 1:1 with `auth.users`. Stores `role` (`admin`/`verifier`), `institution_name` |
| `students` | Student records: name, course, department, batch, auto-generated `student_uid` |
| `certificates` | Full certificate records: immutable snapshot fields, hash, blockchain proof, status |
| `audit_logs` | Every certificate and auth action logged with IP, user agent, metadata |

### Certificate statuses

```
pending  -> issued  -> verified (after successful verification)
pending  -> revoked (admin action)
```

### Storage bucket

Create a **private** bucket named `certificates` in Supabase Storage.
PDFs are uploaded under server-generated paths and served via signed URLs.

---

## Blockchain contract

**Source:** [`certosec-backend/contracts/CertoSecRegistry.sol`](certosec-backend/contracts/CertoSecRegistry.sol)
**ABI:** [`certosec-backend/src/blockchain/contractABI.json`](certosec-backend/src/blockchain/contractABI.json)

| Detail | Value |
| --- | --- |
| Network | Polygon Amoy (chainId `80002`) |
| RPC | `https://polygon-amoy.drpc.org` |
| Contract | `CertoSecRegistry` (Solidity 0.8.24) |
| Explorer | [amoy.polygonscan.com](https://amoy.polygonscan.com) |
| Verification | Sourcify (verified on deployment) |

### On-chain functions

| Function | Type | Description |
| --- | --- | --- |
| `issueCertificate(bytes32 uid, bytes32 hash)` | write | Records a certificate (owner only) |
| `getCertificate(bytes32 uid)` | view | Returns full on-chain record |
| `isIssued(bytes32 uid)` | view | Boolean existence check |
| `verifyCertificate(bytes32 uid, bytes32 hash)` | view | Byte-for-byte hash comparison |
| `owner()` | view | Current contract owner |
| `transferOwnership(address)` | write | Transfer issuance rights |

### How hashing works

The hash stored on-chain is a **SHA-256 digest of the certificate's immutable
identity fields**, serialized as a compact JSON object:

```json
{
  "version": 1,
  "certificateUid": "CERT-2026-000001",
  "studentUid": "STU-2026-001",
  "studentName": "Ada Lovelace",
  "title": "Bachelor of Science in Computer Science",
  "course": "B.Sc. Computer Science",
  "department": "Computer Science",
  "batch": "2026",
  "issueDate": "2026-08-12"
}
```

All strings are trimmed; `null`/`undefined` become `""`. The JSON has no
whitespace. The result is a 64-character lowercase hex string, stored as
a raw `bytes32` on-chain.

**Critical:** mutable fields (status, timestamps, PDF paths, transaction IDs)
are never included in the hash. If any identity field is edited after
issuance, verification will correctly return `TAMPERED`.

---

## API overview

Base path: **`/api/v1`**

### Public (no auth)

| Method | Path | Description |
| --- | --- | --- |
| POST | `/auth/login` | Login (Supabase password grant proxy) |
| POST | `/auth/forgot-password` | Send password reset email |
| POST | `/verify/qr` | Verify by QR scan payload |
| POST | `/verify/uid` | Verify by certificate UID |
| POST | `/verify/transaction` | Verify by transaction hash |
| GET | `/verify?uid=...` | Verify by UID (Flutter alias) |

### Protected (Bearer token required)

| Method | Path | Role | Description |
| --- | --- | --- | --- |
| GET | `/auth/me` | any | Current user profile |
| POST | `/auth/logout` | any | Revoke session |
| GET | `/students` | admin | List students (paginated) |
| POST | `/students` | admin | Create student |
| GET | `/students/:id` | admin | Student detail |
| PUT | `/students/:id` | admin | Update student |
| DELETE | `/students/:id` | admin | Delete student |
| GET | `/certificates` | admin | List certificates (paginated) |
| POST | `/certificates` | admin | Create pending record |
| POST | `/certificates/issue` | admin | Full issuance (record + PDF + chain) |
| GET | `/certificates/:id` | admin | Certificate detail |
| GET | `/certificates/:id/download` | admin | Signed PDF download URL |
| GET | `/dashboard/stats` | admin | Summary statistics |

### Verification verdicts

All verification endpoints return **200** with a result object. The `status`
field indicates the outcome:

| Status | Meaning |
| --- | --- |
| `VALID` | Certificate is authentic and untampered |
| `NOT_FOUND` | No certificate matches the UID |
| `INVALID` | Certificate is revoked or not yet on-chain |
| `TAMPERED` | Hash mismatch — data was altered |
| `BLOCKCHAIN_MISMATCH` | No on-chain record found / RPC failure |
| `TRANSACTION_NOT_FOUND` | Transaction hash not found on network |
| `INVALID_TRANSACTION` | Transaction does not reference CertoSec contract |

---

## Security model

| Concern | Approach |
| --- | --- |
| Authentication | Supabase Auth (ES256 JWT, verified via JWKS at `/auth/v1/.well-known/jwks.json`) |
| Authorization | Role loaded from `profiles` table (never from JWT claims) |
| Private keys | `.env` is gitignored; `BLOCKCHAIN_PRIVATE_KEY` never leaves the server |
| PDF storage | Private bucket, magic-byte validation (`%PDF-`), size-capped, server-generated paths |
| PDF delivery | Short-lived signed URLs (configurable expiry) |
| Rate limiting | 30/min on verification, configurable on login, global API limit |
| Error handling | Stack traces never leaked in production |
| RLS | Enabled on all tables as defence-in-depth (backend uses service-role key) |
| Audit trail | Every certificate and auth action logged with IP, user agent, metadata |

---

## Testing

```bash
cd certosec-backend
npm test              # 48 tests, ~3s
npm run check:env     # validates env config loads
```

Tests use injected fakes — no network calls to Supabase, blockchain, or
external services. Covers:

- **Unit:** hash computation, UID generation, auth middleware, blockchain
  encoding (`toBytes32`, `toHashBytes32`), verification engine logic
- **Integration:** route validation, error responses, auth enforcement

---

## Project status

| Feature | Status |
| --- | --- |
| Auth (login, logout, profile, forgot-password) | Done |
| Admin provisioning on first login | Done |
| Student CRUD (admin-only, paginated, search) | Done |
| Certificate issuance (record + PDF + on-chain proof) | Done |
| Certificate verification (UID, QR, transaction hash) | Done |
| Blockchain contract deployed on Polygon Amoy | Done |
| Contract verified on Sourcify | Done |
| Dashboard stats | Done |
| Audit trail | Done |
| Flutter app (mobile + web) | Done |
| CI / CD pipeline | Planned |
| Production deployment (Polygon mainnet) | Planned |

---

## License

Proprietary — all rights reserved.
