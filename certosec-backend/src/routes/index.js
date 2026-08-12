const router = require('express').Router();
const authRoutes = require('./authRoutes');
const studentRoutes = require('./studentRoutes');
const certificateRoutes = require('./certificateRoutes');
const verificationRoutes = require('./verificationRoutes');
const dashboardRoutes = require('./dashboardRoutes');

router.use('/auth', authRoutes);
router.use('/students', studentRoutes);
router.use('/certificates', certificateRoutes);
router.use('/verify', verificationRoutes);
router.use('/dashboard', dashboardRoutes);

module.exports = router;
