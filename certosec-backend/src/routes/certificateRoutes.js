const router = require('express').Router();
const certificateValidators = require('../validators/certificateValidators');
const certificateController = require('../controllers/certificateController');
const { requireAuth } = require('../middleware/authenticate');
const { requireAdmin } = require('../middleware/requireRole');
const { uploadSinglePdf } = require('../middleware/upload');

router.use(requireAuth, requireAdmin);

router.get('/', certificateValidators.listQuery, certificateController.list);
router.get('/:id', certificateValidators.get, certificateController.get);
router.get('/:id/download', certificateValidators.download, certificateController.download);
router.post('/issue', uploadSinglePdf, certificateValidators.issue, certificateController.issue);
router.post('/', uploadSinglePdf, certificateValidators.create, certificateController.createPending);

module.exports = router;
