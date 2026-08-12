const asyncHandler = require('../utils/asyncHandler');
const { ok, created, noContent } = require('../utils/responses');
const { studentService } = require('../services/index');

const list = asyncHandler(async (req, res) => {
  const { page = 1, pageSize = 20, search, department } = req.query;
  ok(res, await studentService.list({ page, pageSize, search, department }));
});

const get = asyncHandler(async (req, res) => {
  ok(res, await studentService.get(req.params.id));
});

const create = asyncHandler(async (req, res) => {
  created(res, await studentService.create(req.body, req));
});

const update = asyncHandler(async (req, res) => {
  ok(res, await studentService.update(req.params.id, req.body, req));
});

const remove = asyncHandler(async (req, res) => {
  await studentService.remove(req.params.id, req);
  noContent(res);
});

module.exports = { list, get, create, update, remove };
