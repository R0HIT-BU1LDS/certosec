const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const env = require('./config/env');
const { apiLimiter } = require('./middleware/rateLimiters');
const routes = require('./routes');
const { notFound, errorHandler } = require('./middleware/errors');

const app = express();

app.disable('x-powered-by');
app.use(helmet());
app.use(
  cors({
    origin: env.nodeEnv === 'production' ? env.corsOrigins : true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  }),
);
app.use(morgan(env.logFormat));
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: false, limit: '1mb' }));

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'certosec-backend' });
});

app.use('/api/v1', apiLimiter, routes);

app.use(notFound);
app.use(errorHandler);

module.exports = app;
