const asyncHandler = require('../utils/asyncHandler');
const { ok } = require('../utils/responses');
const { dashboardService } = require('../services/index');

const stats = asyncHandler(async (req, res) => {
  ok(res, await dashboardService.stats());
});

module.exports = { stats };
