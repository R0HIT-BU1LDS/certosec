/**
 * Certificate serialization. Matches the frontend `Certificate` model:
 * `{ id, uid, studentId, studentName, title, status, description, issuedAt,
 *    issuerName, transactionHash, chain, blockNumber }` plus bonus fields.
 *
 * NOTE: `studentId` is the STUDENT ROW UUID (`students.id`), because the
 * Flutter details screen resolves the student for PDF enrichment via
 * `StudentsProvider.studentById(studentId)`, which matches by UUID.
 * `studentUid` carries the human roll number for display.
 */
function toCertificateJson(row) {
  return {
    id: row.id,
    uid: row.certificate_uid,
    studentId: row.student_id,
    studentUid: row.student_uid,
    studentName: row.student_name,
    title: row.title,
    description: row.description || null,
    course: row.course,
    department: row.department,
    batch: row.batch,
    status: row.status,
    issuedAt: row.issue_date || null,
    issuerName: row.issuer_name || null,
    certificateHash: row.certificate_hash,
    transactionHash: row.transaction_hash || null,
    chain: row.network || null,
    blockNumber: row.block_number != null ? Number(row.block_number) : null,
    issuerAddress: row.issuer_address || null,
    contractAddress: row.contract_address || null,
    pdfPath: row.pdf_path || null,
    pdfUrl: row.pdf_url || null,
    createdAt: row.created_at || null,
    updatedAt: row.updated_at || null,
  };
}

module.exports = { toCertificateJson };
