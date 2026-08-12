const router = require('express').Router();
const studentValidators = require('../validators/studentValidators');
const studentController = require('../controllers/studentController');
const { requireAuth } = require('../middleware/authenticate');
const { requireAdmin } = require('../middleware/requireRole');

router.use(requireAuth, requireAdmin);

router.get('/', studentValidators.listQuery, studentController.list);
router.get('/:id', studentValidators.get, studentController.get);
router.post('/', studentValidators.create, studentController.create);
router.put('/:id', studentValidators.update, studentController.update);
router.delete('/:id', studentValidators.remove, studentController.remove);

module.exports = router;
