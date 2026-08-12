const app = require('./app');
const env = require('./config/env');
const logger = require('./utils/logger');

app.listen(env.port, () => {
  logger.info(`CertoSec backend listening on port ${env.port} (${env.nodeEnv})`);
  if (env.nodeEnv !== 'production') {
    logger.info(`API base: http://localhost:${env.port}/api/v1`);
  }
});
