const asyncHandler = require('../utils/asyncHandler');
const { ok, created } = require('../utils/responses');
const { certificateService } = require('../services/index');

const list = asyncHandler(async (req, res) => {
  const { page = 1, pageSize = 20, search, status } = req.query;
  ok(res, await certificateService.list({ page, pageSize, search, status }));
});

const get = asyncHandler(async (req, res) => {
  ok(res, await certificateService.get(req.params.id));
});

/** Full issuance: record + optional PDF + on-chain proof. */
const issue = asyncHandler(async (req, res) => {
  created(res, await certificateService.issue(req.body, req, req.file));
});

/** Record-only creation (status pending, no blockchain). */
const createPending = asyncHandler(async (req, res) => {
  created(res, await certificateService.createPending(req.body, req, req.file));
});

const download = asyncHandler(async (req, res) => {
  ok(res, await certificateService.getDownloadUrl(req.params.id, req));
});

module.exports = { list, get, issue, createPending, download };
