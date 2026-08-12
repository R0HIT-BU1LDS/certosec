const router = require('express').Router();
const dashboardController = require('../controllers/dashboardController');
const { requireAuth } = require('../middleware/authenticate');
const { requireAdmin } = require('../middleware/requireRole');

router.use(requireAuth, requireAdmin);
router.get('/stats', dashboardController.stats);

module.exports = router;
