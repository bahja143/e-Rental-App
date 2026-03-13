import React, { useCallback, useEffect, useState } from 'react';
import { Row, Col, Table, Button, Spinner, Pagination, Form, Modal, Alert } from 'react-bootstrap';
import { getCompanies, createCompany, updateCompany, deleteCompany } from '../../services/rentalApi';

const emptyForm = {
  name_en: '',
  name_so: '',
  address_en: '',
  address_so: '',
  emails_csv: '',
  phones_csv: ''
};

const csvToArray = (value) =>
  (value || '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);

const arrayToCsv = (value) => (Array.isArray(value) ? value.join(', ') : '');

const CompaniesManager = () => {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [pagination, setPagination] = useState({ totalPages: 1, totalItems: 0 });
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(emptyForm);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState({ error: '', success: '' });

  const loadRows = useCallback(async () => {
    setLoading(true);
    try {
      const res = await getCompanies({ page, limit: 10, search: search.trim() || undefined });
      setRows(res.data?.data ?? []);
      const p = res.data?.pagination ?? {};
      setPagination({ totalPages: p.totalPages ?? 1, totalItems: p.totalItems ?? 0 });
    } catch (e) {
      console.error(e);
      setMessage({ error: 'Failed to load companies.', success: '' });
    } finally {
      setLoading(false);
    }
  }, [page, search]);

  useEffect(() => {
    loadRows();
  }, [loadRows]);

  const openCreate = () => {
    setEditing(null);
    setForm(emptyForm);
    setShowModal(true);
  };

  const openEdit = (row) => {
    setEditing(row);
    setForm({
      name_en: row.name_en ?? '',
      name_so: row.name_so ?? '',
      address_en: row.address_en ?? '',
      address_so: row.address_so ?? '',
      emails_csv: arrayToCsv(row.emails),
      phones_csv: arrayToCsv(row.phones)
    });
    setShowModal(true);
  };

  const save = async () => {
    setSaving(true);
    setMessage({ error: '', success: '' });
    try {
      const payload = {
        name_en: form.name_en.trim(),
        name_so: form.name_so.trim() || null,
        address_en: form.address_en.trim(),
        address_so: form.address_so.trim() || null,
        emails: csvToArray(form.emails_csv),
        phones: csvToArray(form.phones_csv)
      };
      if (payload.emails.length === 0) delete payload.emails;
      if (payload.phones.length === 0) delete payload.phones;

      if (editing?.id) {
        await updateCompany(editing.id, payload);
        setMessage({ success: 'Company updated.', error: '' });
      } else {
        await createCompany(payload);
        setMessage({ success: 'Company created.', error: '' });
      }
      setShowModal(false);
      loadRows();
    } catch (e) {
      console.error(e);
      setMessage({ error: e?.response?.data?.error || 'Save failed.', success: '' });
    } finally {
      setSaving(false);
    }
  };

  const remove = async (id) => {
    if (!window.confirm('Delete this company?')) return;
    try {
      await deleteCompany(id);
      setMessage({ success: 'Company deleted.', error: '' });
      loadRows();
    } catch (e) {
      console.error(e);
      setMessage({ error: e?.response?.data?.error || 'Delete failed.', success: '' });
    }
  };

  return (
    <div className="rental-page">
      <div className="advanced-panel mb-0">
        <div className="advanced-panel-header">
          <h5>
            <i className="feather icon-briefcase me-2" />
            Companies
          </h5>
          <div className="d-flex gap-2 flex-wrap">
            <Form.Control
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
              placeholder="Search"
              style={{ width: 160 }}
            />
            <Button size="sm" variant="outline-primary" onClick={loadRows}>
              Refresh
            </Button>
            <Button size="sm" variant="primary" onClick={openCreate}>
              Add Company
            </Button>
          </div>
        </div>
        <div>
              {message.error && <Alert variant="danger">{message.error}</Alert>}
              {message.success && <Alert variant="success">{message.success}</Alert>}
              {loading && rows.length === 0 ? (
                <div className="text-center py-5">
                  <Spinner animation="border" style={{ color: '#e7b904' }} />
                  <p className="text-muted mt-2">Loading...</p>
                </div>
              ) : (
                <>
                  <div className="table-responsive rental-table-wrap">
                    <Table hover responsive className="rental-table mb-0 align-middle">
                      <thead>
                        <tr>
                          <th>ID</th>
                          <th>Name</th>
                          <th>Address</th>
                          <th>Emails</th>
                          <th>Phones</th>
                          <th className="text-end">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {rows.map((r) => (
                          <tr key={r.id}>
                            <td>{r.id}</td>
                            <td className="fw-bold">{r.name_en}</td>
                            <td>{r.address_en}</td>
                            <td>{arrayToCsv(r.emails) || '-'}</td>
                            <td>{arrayToCsv(r.phones) || '-'}</td>
                            <td className="text-end">
                              <Button size="sm" variant="outline-primary" className="me-2" onClick={() => openEdit(r)}>
                                Edit
                              </Button>
                              <Button size="sm" variant="outline-danger" onClick={() => remove(r.id)}>
                                Delete
                              </Button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </Table>
                  </div>
                  {pagination.totalPages > 1 && (
                    <Pagination className="mt-3 mb-0">
                      <Pagination.Prev disabled={page <= 1} onClick={() => setPage((p) => Math.max(1, p - 1))} />
                      <Pagination.Item active>{page}</Pagination.Item>
                      <Pagination.Next
                        disabled={page >= pagination.totalPages}
                        onClick={() => setPage((p) => Math.min(pagination.totalPages, p + 1))}
                      />
                    </Pagination>
                  )}
                </>
              )}
        </div>
      </div>

      <Modal show={showModal} onHide={() => setShowModal(false)} centered size="lg" className="rental-modal">
        <Modal.Header closeButton className="rental-modal-header">
          <Modal.Title>
            <i className="feather icon-briefcase me-2" />
            {editing ? 'Edit Company' : 'Create Company'}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Row className="g-3">
            <Col md={6}>
              <Form.Label>Name EN</Form.Label>
              <Form.Control value={form.name_en} onChange={(e) => setForm((f) => ({ ...f, name_en: e.target.value }))} />
            </Col>
            <Col md={6}>
              <Form.Label>Name SO</Form.Label>
              <Form.Control value={form.name_so} onChange={(e) => setForm((f) => ({ ...f, name_so: e.target.value }))} />
            </Col>
            <Col md={6}>
              <Form.Label>Address EN</Form.Label>
              <Form.Control value={form.address_en} onChange={(e) => setForm((f) => ({ ...f, address_en: e.target.value }))} />
            </Col>
            <Col md={6}>
              <Form.Label>Address SO</Form.Label>
              <Form.Control value={form.address_so} onChange={(e) => setForm((f) => ({ ...f, address_so: e.target.value }))} />
            </Col>
            <Col md={6}>
              <Form.Label>Emails (comma-separated)</Form.Label>
              <Form.Control value={form.emails_csv} onChange={(e) => setForm((f) => ({ ...f, emails_csv: e.target.value }))} />
            </Col>
            <Col md={6}>
              <Form.Label>Phones (comma-separated)</Form.Label>
              <Form.Control value={form.phones_csv} onChange={(e) => setForm((f) => ({ ...f, phones_csv: e.target.value }))} />
            </Col>
          </Row>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="outline-secondary" onClick={() => setShowModal(false)}>
            Cancel
          </Button>
          <Button variant="primary" onClick={save} disabled={saving}>
            {saving ? 'Saving...' : 'Save'}
          </Button>
        </Modal.Footer>
      </Modal>
    </div>
  );
};

export default CompaniesManager;
