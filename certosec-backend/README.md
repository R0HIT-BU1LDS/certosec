# CertoSec V2 Backend

REST API for blockchain-backed certificate issuance and verification. Built
with **Express**, **Supabase** (PostgreSQL, Auth, Storage) and **ethers.js**
on **Polygon Amoy** (testnet).

```
Flutter app ──HTTP──▶ Express API ──▶ Supabase (Postgres, Auth, Storage)
                           │
                           └────────▶ Polygon Amoy (CertoSecRegistry contract)
```

The backend is the **only** component that touches the blockchain and the
database. The Flutter app issues HTTP requests and verifies certificates
through this API only.

## Getting started

```bash
npm install
cp .env.example .env      # fill in values (see table below)
npm run dev               # http://localhost:3000/api/v1
```

The server fails fast at startup if `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
`SUPABASE_SERVICE_ROLE_KEY`, `BLOCKCHAIN_RPC_URL` or `BLOCKCHAIN_CHAIN_ID`
are missing.

### Environment variables

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `SUPABASE_URL` | yes | | Supabase project URL |
| `SUPABASE_ANON_KEY` | yes | | Anon key (auth login proxy) |
| `SUPABASE_SERVICE_ROLE_KEY` | yes | | Server-side data access (never exposed to client) |
| `SUPABASE_JWT_SECRET` | no | | Legacy HS256 only; modern projects verify via JWKS automatically |
| `BLOCKCHAIN_RPC_URL` | yes | | Polygon Amoy RPC (`https://polygon-amoy.drpc.org`) |
| `BLOCKCHAIN_CHAIN_ID` | no | `80002` | |
| `BLOCKCHAIN_PRIVATE_KEY` | for issuance | | Hex private key (`0x...`) of the contract owner wallet |
| `CONTRACT_ADDRESS` | for issuance | | Deployed `CertoSecRegistry` address |
| `NETWORK_NAME` | no | `Polygon Amoy` | Display name on certificates |
| `ADMIN_EMAIL` | no | | Email granted `admin` role on first login |
| `STORAGE_BUCKET` | no | `certificates` | Private Supabase Storage bucket |
| `MAX_PDF_MB` | no | `10` | PDF upload size cap |
| `CORS_ORIGINS` | no | | Comma-separated allowed origins |
| `PORT` | no | `3000` | |

### Database

Run `src/database/schema.sql` in the Supabase SQL editor. Creates `profiles`,
`students`, `certificates`, `audit_logs`, the `updated_at` trigger, indexes
and enables RLS. Also create a **private** `certificates` storage bucket.

## Smart contract

Solidity source: **`contracts/CertoSecRegistry.sol`**
ABI: **`src/blockchain/contractABI.json`**

### Functions

| Function | Mutability | Description |
| --- | --- | --- |
| `issueCertificate(bytes32 uid, bytes32 hash)` | nonpayable | Records a certificate on-chain (owner only) |
| `getCertificate(bytes32 uid)` | view | Returns full on-chain record |
| `isIssued(bytes32 uid)` | view | True if the UID has been issued |
| `verifyCertificate(bytes32 uid, bytes32 hash)` | view | Byte-for-byte hash comparison |
| `owner()` | view | Current contract owner |
| `transferOwnership(address)` | nonpayable | Transfer ownership to a new wallet |

### Encoding

- `uid` is UTF-8 encoded into bytes32 via `encodeBytes32String` (UIDs like
  `CERT-2026-000001` are 16 bytes, well within 32).
- `hash` is the raw SHA-256 digest passed as bytes32 (`0x` + 64 hex chars).
  The on-chain comparison is byte-for-byte, so the digest must match exactly
  what `hashService.js` produces.

### Deploying

```bash
node scripts/checkContract.js 0xcF7AD8be94266bB078f0c053d8E967Acd42C1847
```

Read-only check (no gas): verifies the address has code, `owner()` matches
your signing wallet, and all read functions respond.

## Canonical certificate hash

Computed over the certificate's **immutable identity fields only** (status,
timestamps, storage paths are never hashed):

```
{ "version": 1,
  "certificateUid": "CERT-2026-000001",
  "studentUid":     "STU-2026-001",
  "studentName":    "Ada Lovelace",
  "title":          "Bachelor of Science in Computer Science",
  "course":         "B.Sc. Computer Science",
  "department":     "Computer Science",
  "batch":          "2026",
  "issueDate":      "2026-08-12" }
```

Serialization: `JSON.stringify` with the fixed key order above, no
whitespace, all strings trimmed, `null`/`undefined` replaced with `""`.
Hash = lowercase SHA-256 hex (64 chars). See `src/services/hashService.js`.

## API

Base path: **`/api/v1`**. Authenticated endpoints accept a Supabase access
token as `Authorization: Bearer <token>`.

### Response shapes

Success:
```json
{ "id": "...", "studentUid": "STU-2026-001", "..." : "..." }
```

Error:
```json
{
  "success": false,
  "error": { "code": "VALIDATION_ERROR", "message": "Please correct the highlighted fields." },
  "errors": { "email": "Enter a valid email address." }
}
```

### Authentication

| Method | Path | Auth | Description |
| --- | --- | --- | --- |
| POST | `/auth/login` | -- | Supabase password grant proxy; returns access/refresh tokens |
| GET | `/auth/me` | yes | Current profile (`id`, `email`, `name`, `role`, `institutionName`) |
| POST | `/auth/logout` | yes | Revokes the session token |
| POST | `/auth/forgot-password` | -- | Sends a reset link via Supabase |

Roles are loaded from the `profiles` table only. `ADMIN_EMAIL` gets the
`admin` role on first login; everyone else gets `verifier`.

### Students (admin)

| Method | Path | Description |
| --- | --- | --- |
| GET | `/students?page=&pageSize=&search=&department=` | Paginated list |
| GET | `/students/:id` | Detail |
| POST | `/students` | Create |
| PUT | `/students/:id` | Update |
| DELETE | `/students/:id` | Delete (cascades to certificates) |

### Certificates (admin)

| Method | Path | Description |
| --- | --- | --- |
| GET | `/certificates?page=&pageSize=&search=&status=` | Paginated list |
| GET | `/certificates/:id` | Detail (by UUID or UID) |
| GET | `/certificates/:id/download` | Signed PDF download URL |
| POST | `/certificates/issue` | Full issuance: record + PDF + on-chain proof |
| POST | `/certificates` | Record-only (`status: pending`, no blockchain) |

**Issuance:** `studentId` must be the student UUID, `title` is required.
A unique `CERT-YYYY-NNNNNN` UID is auto-generated. On blockchain failure
the record stays `pending` and the API returns `502 BLOCKCHAIN_ERROR`.

### Verification (public, rate-limited 30/min)

| Method | Path | Body / Query |
| --- | --- | --- |
| POST | `/verify/qr` | `{ payload }` -- verification URL or bare UID |
| POST | `/verify/uid` | `{ uid: "CERT-2026-000001" }` |
| POST | `/verify/transaction` | `{ txHash: "0x..." }` |
| GET | `/verify?uid=...` | Flutter client alias |
| GET | `/verify?txHash=...` | Flutter client alias |

**Verdicts:** `VALID`, `NOT_FOUND`, `INVALID` (revoked / not yet on-chain),
`TAMPERED` (hash mismatch), `BLOCKCHAIN_MISMATCH` (no on-chain record / RPC
down), `TRANSACTION_NOT_FOUND`, `INVALID_TRANSACTION`.

### Dashboard (admin)

| Method | Path | Description |
| --- | --- | --- |
| GET | `/dashboard/stats` | Students, certificates, issued today, verified, pending |

## Project structure

```
src/
  app.js                         Express app setup
  server.js                      Entrypoint
  config/
    env.js                       Typed env access, fails fast
    supabase.js                  Service-role + anon clients
  contracts/
    CertoSecRegistry.sol         Solidity source
  blockchain/
    blockchainProvider.js        ethers provider / wallet / contract
    blockchainService.js         issue, read, verify, tx lookup
    contractABI.json             ABI matching CertoSecRegistry.sol
  database/
    schema.sql                   Supabase schema (run once)
  services/
    hashService.js               Canonical SHA-256 hash
    verificationService.js       Single verification engine
    certificateService.js        Issuance pipeline
    studentService.js            Student CRUD
    authService.js               Login, profile, password reset
    storageService.js            PDF validation, upload, signed URLs
    auditService.js              Never-failing audit trail
    index.js                     Dependency container
  models/                        snake_case -> camelCase serializers
  repositories/                  Supabase data access
  controllers/                   Thin HTTP handlers
  validators/                    express-validator chains
  routes/                        Mounted under /api/v1
  middleware/                     Auth, RBAC, rate limits, uploads, errors
  utils/                         ApiError, asyncHandler, logger, uidGenerator
scripts/
  checkContract.js               Post-deployment verification
tests/
  unit/                          Hash, auth middleware, UID, verification
  integration/                   Route + validator + error handling
```

## Testing

```bash
npm test            # jest --runInBand (unit + integration)
npm run check:env   # validates env config loads
```

48 tests, no network calls. Repositories and services use injected fakes.

## Security notes

- Service-role key is server-only, never exposed to client.
- App role from `profiles` table only; Supabase JWT role claim is ignored.
- Access tokens verified via JWKS (`/auth/v1/.well-known/jwks.json`, ES256).
- PDFs: size-capped, magic-byte checked, server-generated paths, signed URLs.
- Error handler never leaks stack traces in production.
- Rate limits on login and verification endpoints.
- `.env` is gitignored; private keys are never committed.
