# CertoSec V2 Backend

Blockchain-backed certificate issuance and verification API for the CertoSec
Flutter app. Built with **Node.js + Express**, **Supabase** (PostgreSQL, Auth,
Storage) and **ethers.js** on **Polygon Amoy** (testnet).

The backend is the **only** component that talks to the blockchain. The Flutter
app issues requests, stores nothing on-chain, and verifies certificates through
this API.

```
 Flutter app ──HTTP──▶ Express API ──▶ Supabase (PostgreSQL, Auth, Storage)
                          │
                          └────────▶ Polygon Amoy (ethers.js + deployed contract)
```

## Architecture

```
src/
├── app.js                 # Express app: helmet, cors, morgan, json limits, routes, error handler
├── server.js              # entrypoint (PORT)
├── config/
│   ├── env.js             # typed env access; fails fast on missing required vars
│   └── supabase.js        # service-role client + anon client
├── database/schema.sql    # authoritative schema (run once in the Supabase SQL editor)
├── blockchain/
│   ├── blockchainProvider.js  # ethers provider / wallet / contract (lazy singletons)
│   ├── blockchainService.js   # all on-chain calls (issue, read, verify, tx lookup)
│   └── contractABI.json       # ⚠️ placeholder ABI — replace with the real Remix ABI
├── models/                # snake_case → camelCase serializers (match Flutter models)
├── repositories/          # thin Postgres data access (no business rules)
├── services/
│   ├── hashService.js         # canonical certificate hash (THE source of truth)
│   ├── verificationService.js # the single verification engine
│   ├── certificateService.js  # issue (record + PDF + on-chain) / createPending
│   ├── studentService.js      # student CRUD + uniqueness checks
│   ├── authService.js         # login proxy, /me, logout, forgot-password
│   ├── storageService.js      # PDF magic-byte check, upload, signed URLs
│   ├── auditService.js        # never-failing audit trail
│   └── index.js               # dependency container (tests inject their own fakes)
├── controllers/           # thin HTTP layer
├── validators/            # express-validator chains + shared regexes
├── routes/                # mounted under /api/v1
├── middleware/
│   ├── authenticate.js    # Supabase JWT verification (local HS256) + profile load
│   ├── requireRole.js     # requireRole(...)/requireAdmin
│   ├── rateLimiters.js    # login / verification / global limits
│   ├── upload.js          # multer single 'pdf' (in-memory, size-capped)
│   └── errors.js          # centralized error mapping (never leaks stacks)
└── utils/                 # ApiError, asyncHandler, responses, uidGenerator, logger, db
tests/                     # jest (unit + supertest integration)
```

## Getting started

Prerequisites: Node.js >= 18.

```bash
cd certosec-backend
npm install
cp .env.example .env      # fill in your values (see below)
npm run dev               # nodemon on PORT (default 3000)
```

The app fails fast at startup if `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
`SUPABASE_SERVICE_ROLE_KEY`, `BLOCKCHAIN_RPC_URL` or `BLOCKCHAIN_CHAIN_ID` are
missing.

### Environment variables

| Variable | Required | Description |
| --- | --- | --- |
| `SUPABASE_URL` | yes | Supabase project URL |
| `SUPABASE_ANON_KEY` | yes | Anon key (used for the auth login proxy) |
| `SUPABASE_SERVICE_ROLE_KEY` | yes | Service-role key (server-side data access) |
| `SUPABASE_JWT_SECRET` | no | Legacy HS256 projects only; modern projects sign with ES256 and tokens are verified against the project's public keys (JWKS) automatically |
| `BLOCKCHAIN_RPC_URL` | yes | Polygon Amoy RPC endpoint |
| `BLOCKCHAIN_CHAIN_ID` | no | Default `80002` |
| `BLOCKCHAIN_PRIVATE_KEY` | for issuance | Issuer wallet private key (hex, `0x...`) |
| `CONTRACT_ADDRESS` | for issuance | Deployed CertoSec contract address |
| `NETWORK_NAME` | no | Display name, default `Polygon Amoy` |
| `ADMIN_EMAIL` | no | Email granted the `admin` role on first login |
| `STORAGE_BUCKET` | no | Default `certificates` |
| `MAX_PDF_MB` | no | PDF size cap, default `10` |
| `CORS_ORIGINS` | no | Comma-separated allowed origins (production only) |
| `PORT` | no | Default `3000` |

### Database

Open the Supabase SQL editor and run `src/database/schema.sql`. It creates
`profiles`, `students`, `certificates`, `audit_logs`, the `updated_at` trigger,
indexes and enables RLS. The storage bucket (`certificates`) must be created
and private.

## Blockchain contract

`src/blockchain/contractABI.json` is a **placeholder**. Deploy the CertoSec
contract with Remix, then:

1. Replace `contractABI.json` with the real ABI (or use Remix's generated ABI).
2. Set `CONTRACT_ADDRESS` (and a funded `BLOCKCHAIN_PRIVATE_KEY`).

The expected interface (bytes32 strings are UTF-8 encoded, e.g.
`encodeBytes32String` in ethers v6):

```
issueCertificate(bytes32 uid, bytes32 hash)
getCertificate(bytes32 uid) -> (bytes32 uid, bytes32 hash, address issuer, uint256 issuedAt, bool exists)
isIssued(bytes32 uid) -> bool
verifyCertificate(bytes32 uid, bytes32 hash) -> bool
```

## Canonical certificate hash

The hash stored on-chain is computed over the certificate's immutable identity
fields only (never mutable metadata like status or timestamps):

```
version       1
certificateUid  CERT-2026-000001
studentUid      STU-2026-001
studentName     Ada Lovelace
title           Bachelor of Science in Computer Science
course          B.Sc. Computer Science
department      Computer Science
batch           2026
issueDate       2026-08-12 (UTC, YYYY-MM-DD)
```

Serialization: `JSON.stringify` of an object with the fixed key order above, no
whitespace, all strings trimmed, `null`/`undefined` → `""`. Hash = lowercase
SHA-256 hex. See `src/services/hashService.js` — change nothing there without a
format bump (`CANONICAL_FORMAT_VERSION`).

## API

Base path: **`/api/v1`**. Auth endpoints accept the **Supabase access token**
(returned by login) as `Authorization: Bearer <token>`.

### Response shapes

Success responses return the resource payload at the top level:

```json
{ "id": "...", "studentUid": "STU-2026-001", "...": "..." }
```

Errors:

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
| POST | `/auth/login` | – | Proxies the Supabase password grant; returns `{ accessToken, refreshToken, expiresIn, user }` |
| GET | `/auth/me` | yes | Current profile (`id`, `email`, `name`, `role`, `institutionName`) |
| POST | `/auth/logout` | yes | Revokes the session token |
| POST | `/auth/forgot-password` | – | Sends a reset link via Supabase |

The app role is always loaded from the `profiles` table — never from the JWT or
the client. `ADMIN_EMAIL` is granted `admin` on first login; everyone else gets
`verifier`. Missing profiles are auto-provisioned.

### Students (admin)

| Method | Path | Description |
| --- | --- | --- |
| GET | `/students?page=&pageSize=&search=&department=` | Paginated list `{ items, total, page, pageSize, totalPages }` |
| GET | `/students/:id` | Detail |
| POST | `/students` | Create (`studentId`, `name`, `email`, `department`, `batch`, `course`, `phone?`, `profilePhotoUrl?`) |
| PUT | `/students/:id` | Update |
| DELETE | `/students/:id` | Delete (cascades to certificates) |

### Certificates (admin)

| Method | Path | Description |
| --- | --- | --- |
| GET | `/certificates?page=&pageSize=&search=&status=` | Paginated list |
| GET | `/certificates/:id` | Detail (by UUID or `CERT-YYYY-NNNNNN`) |
| GET | `/certificates/:id/download` | Signed download URL for the stored PDF (404 if none) |
| POST | `/certificates/issue` | Full issuance: record + optional `pdf` file + on-chain proof |
| POST | `/certificates` | Record-only creation (`status: pending`, no blockchain) |

**Issuance (full):** `studentId` must be the student record UUID (the Flutter
app's `StudentsProvider` matches by `student.id`). `title` is required,
`description` optional. An optional `multipart/form-data` file field `pdf`
stores the signed PDF; JSON-only requests work fine. A unique
`CERT-YYYY-NNNNNN` UID is auto-generated (year-scoped, retried on collision).
If the blockchain call fails, the row is left `status: pending` and the API
returns `502 BLOCKCHAIN_ERROR`.

### Verification (public, rate-limited 30/min)

All three entry points run through the same `verificationService` engine. A
verdict is always returned as a **200 result object** — a missing or tampered
certificate is a verdict, not an HTTP error.

| Method | Path | Body / Query |
| --- | --- | --- |
| POST | `/verify/qr` | `{ payload }` — a verification URL **or** a bare UID |
| POST | `/verify/uid` | `{ uid: "CERT-2026-000001" }` |
| POST | `/verify/transaction` | `{ txHash: "0x..." }` |
| GET | `/verify?uid=...` or `/verify?txHash=...` | Alias for the Flutter client |

Response (all keys below are returned):

```json
{
  "valid": true,
  "status": "VALID",
  "message": "This certificate is authentic.",
  "verifiedAt": "2026-08-12T10:00:00.000Z",
  "certificate": {
    "uid": "CERT-2026-000001",
    "certificateUid": "CERT-2026-000001",
    "studentName": "Ada Lovelace",
    "title": "...",
    "certificateTitle": "...",
    "course": "...",
    "department": "...",
    "batch": "2026",
    "issuedAt": "2026-08-12",
    "issueDate": "2026-08-12",
    "transactionHash": "0x...",
    "issuerAddress": "0x...",
    "blockNumber": 42,
    "network": "Polygon Amoy"
  }
}
```

Dual key names (`uid`/`certificateUid`, `title`/`certificateTitle`,
`issuedAt`/`issueDate`) keep the existing Flutter parsers working. Successful
verification flips an `issued` certificate to `verified`.

**Verdicts:** `VALID`, `NOT_FOUND`, `INVALID` (revoked or not yet issued),
`TAMPERED` (stored hash ≠ on-chain hash, or recomputed hash ≠ stored hash),
`BLOCKCHAIN_MISMATCH` (no on-chain record / RPC failure),
`TRANSACTION_NOT_FOUND`, `INVALID_TRANSACTION` (tx does not reference our
contract).

### Dashboard (admin)

| Method | Path | Description |
| --- | --- | --- |
| GET | `/dashboard/stats` | `{ totalStudents, totalCertificates, certificatesIssuedToday, verifiedCertificates, pendingCertificates }` |

## Testing

```bash
npm test          # jest --runInBand (unit + integration)
npm run check:env # validates env configuration loads
```

Tests never hit the network: repositories/services are injected with fakes, and
the integration suite exercises routing, validators and error handling with
supertest. Requires `BLOCKCHAIN_PRIVATE_KEY` and a fake `CONTRACT_ADDRESS` are
present in env (tests set their own defaults).

## Security notes

- Service-role key is server-only, never exposed to the client.
- App role comes from the `profiles` table only; the Supabase JWT role claim is
  ignored.
- Access tokens are verified locally against the project's published public
  keys (`/auth/v1/.well-known/jwks.json`, ES256) via `jose`, so the API stays
  available even if the Supabase auth host is slow. No shared JWT secret to
  manage or leak.
- PDFs are size-capped, magic-byte checked (`%PDF-`), stored under
  server-generated paths, and served via short-lived signed URLs.
- Error handler never leaks stack traces in production.
- Per-route rate limits on login and verification; global limit on the API.

## Known blockers / handoff

- **Live issuance needs:** the real `contractABI.json` from Remix,
  `CONTRACT_ADDRESS`, and a funded `BLOCKCHAIN_PRIVATE_KEY`.
- **Supabase:** run `schema.sql`; create the private `certificates` bucket.
- Frontend cosmetic note: the generated PDF shows the certificate UUID in the
  "Student ID" cell; a small frontend tweak (prefer `studentUid`) is suggested
  later.
