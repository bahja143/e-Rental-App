import React, { useState, useEffect, useCallback } from 'react';

// react-bootstrap
import { Table, Button, Spinner, Pagination, Form } from 'react-bootstrap';

// project import
import { getListingRentals, updateListingRental } from '../../services/rentalApi';

// ==============================|| RENTALS LIST ||============================== //

const RentalsList = () => {
  const [rentals, setRentals] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState('');
  const [pagination, setPagination] = useState({ totalPages: 1, totalItems: 0 });

  const fetchRentals = useCallback(async () => {
    setLoading(true);
    try {
      const params = { page, limit: 10 };
      if (statusFilter) params.status = statusFilter;
      const res = await getListingRentals(params);
      setRentals(res.data?.data ?? []);
      const p = res.data?.pagination ?? {};
      setPagination({
        totalPages: p.totalPages ?? 1,
        totalItems: p.totalItems ?? 0
      });
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, [page, statusFilter]);

  useEffect(() => {
    fetchRentals();
  }, [fetchRentals]);

  const handleStatusChange = async (id, status) => {
    try {
      await updateListingRental(id, { status });
      fetchRentals();
    } catch (e) {
      console.error(e);
      alert(e?.message ?? 'Update failed');
    }
  };

  if (loading && rentals.length === 0) {
    return (
      <div className="rental-page">
        <div className="advanced-panel">
          <div className="text-center py-5">
            <Spinner animation="border" style={{ color: '#e7b904' }} />
            <p className="text-muted mt-2">Loading rentals...</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="rental-page">
      <div className="advanced-panel mb-0">
        <div className="advanced-panel-header">
          <h5>
            <i className="feather icon-calendar me-2" />
            Rentals
          </h5>
          <Form.Select
            style={{ width: 160 }}
            value={statusFilter}
            onChange={(e) => {
              setStatusFilter(e.target.value);
              setPage(1);
            }}
          >
            <option value="">All statuses</option>
            <option value="pending">Pending</option>
            <option value="confirmed">Confirmed</option>
            <option value="cancelled">Cancelled</option>
            <option value="completed">Completed</option>
          </Form.Select>
        </div>
        <div>
              {rentals.length === 0 ? (
                <p className="text-muted">No rentals found.</p>
              ) : (
                <>
                  <div className="table-responsive rental-table-wrap">
                    <Table hover responsive className="rental-table mb-0 align-middle">
                      <thead>
                        <tr>
                          <th>ID</th>
                          <th>Listing</th>
                          <th>Renter</th>
                          <th>Start</th>
                          <th>End</th>
                          <th>Rent Type</th>
                          <th>Status</th>
                          <th>Total</th>
                          <th>Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {rentals.map((r) => (
                          <tr key={r.id}>
                            <td>{r.id}</td>
                            <td className="fw-bold">{r.listing?.title ?? r.list_id}</td>
                            <td>{r.renter?.name ?? r.renter_id}</td>
                            <td>{r.start_date ? new Date(r.start_date).toLocaleDateString() : '-'}</td>
                            <td>{r.end_date ? new Date(r.end_date).toLocaleDateString() : '-'}</td>
                            <td>{r.rent_type ?? '-'}</td>
                            <td>
                              <span
                                className={`badge bg-${
                                  r.status === 'confirmed'
                                    ? 'success'
                                    : r.status === 'cancelled'
                                      ? 'danger'
                                      : r.status === 'completed'
                                        ? 'info'
                                        : 'secondary'
                                }`}
                              >
                                {r.status}
                              </span>
                            </td>
                            <td>${r.total ?? r.subtotal ?? '-'}</td>
                            <td className="text-end">
                              {r.status === 'pending' && (
                                <>
                                  <Button
                                    size="sm"
                                    variant="success"
                                    className="me-1"
                                    onClick={() => handleStatusChange(r.id, 'confirmed')}
                                  >
                                    Confirm
                                  </Button>
                                  <Button size="sm" variant="danger" onClick={() => handleStatusChange(r.id, 'cancelled')}>
                                    Cancel
                                  </Button>
                                </>
                              )}
                              {r.status === 'confirmed' && (
                                <Button size="sm" variant="info" onClick={() => handleStatusChange(r.id, 'completed')}>
                                  Complete
                                </Button>
                              )}
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
    </div>
  );
};

export default RentalsList;
