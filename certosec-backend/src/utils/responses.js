/**
 * Success responses return the resource payload DIRECTLY at the top level
 * (e.g. { accessToken, user } or { id, uid, ... }). This matches the Flutter
 * model parsers, which read the body as the model itself.
 *
 * Error responses use the documented shape:
 *   { success: false, error: { code, message }, errors?: { field: msg } }
 */
function ok(res, data, status = 200) {
  return res.status(status).json(data);
}

function created(res, data) {
  return ok(res, data, 201);
}

function noContent(res) {
  return res.status(204).send();
}

module.exports = { ok, created, noContent };
