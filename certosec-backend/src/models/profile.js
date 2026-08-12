/**
 * Profile serialization. The frontend `User` model expects
 * `{ id, name, email, role, avatarUrl }`, so `full_name` maps to `name`.
 */
function toProfileJson(row) {
  return {
    id: row.id,
    name: row.full_name || '',
    email: row.email,
    role: row.role,
    institutionName: row.institution_name || null,
    avatarUrl: row.avatar_url || null,
    createdAt: row.created_at || null,
    updatedAt: row.updated_at || null,
  };
}

module.exports = { toProfileJson };
