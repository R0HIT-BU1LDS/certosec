/**
 * Wraps an async handler so rejected promises are forwarded to the Express
 * error middleware instead of crashing the process.
 */
module.exports = function asyncHandler(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};
