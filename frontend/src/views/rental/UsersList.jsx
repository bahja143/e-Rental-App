import React, { useState, useEffect } from 'react';

// react-bootstrap
import { Table, Spinner, Pagination, Form, Button } from 'react-bootstrap';

// project import
import { getUsers } from '../../services/rentalApi';

// ==============================|| USERS LIST ||============================== //

const UsersList = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [searchInput, setSearchInput] = useState('');
  const [appliedSearch, setAppliedSearch] = useState('');
  const [pagination, setPagination] = useState({ totalPages: 1, totalItems: 0 });

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    const params = { page, limit: 10 };
    if (appliedSearch) params.search = appliedSearch;
    getUsers(params)
      .then((res) => {
        if (!cancelled) {
          const data = res.data?.data;
          const p = res.data?.pagination ?? {};
          setUsers(Array.isArray(data) ? data : []);
          setPagination({
            totalPages: p.totalPages ?? 1,
            totalItems: p.totalItems ?? 0
          });
        }
      })
      .catch((e) => {
        if (!cancelled) {
          console.error(e);
          setUsers([]);
        }
      })
      .finally(() => !cancelled && setLoading(false));
    return () => {
      cancelled = true;
    };
  }, [page, appliedSearch]);

  const handleSearch = (e) => {
    e.preventDefault();
    setAppliedSearch(searchInput.trim());
    setPage(1);
  };

  if (loading && users.length === 0) {
    return (
      <div className="rental-page">
        <div className="advanced-panel">
          <div className="text-center py-5">
            <Spinner animation="border" style={{ color: '#e7b904' }} />
            <p className="text-muted mt-2">Loading users...</p>
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
            <i className="feather icon-users me-2" />
            Users
          </h5>
          <Form className="d-flex gap-2" onSubmit={handleSearch}>
            <Form.Control
              type="text"
              placeholder="Search by name, email, city"
              value={searchInput}
              onChange={(e) => setSearchInput(e.target.value)}
              style={{ width: 200 }}
            />
            <Button type="submit" variant="primary" size="sm">
              Search
            </Button>
          </Form>
        </div>
        <div>
              {users.length === 0 ? (
                <p className="text-muted">No users found.</p>
              ) : (
                <>
                  <div className="table-responsive rental-table-wrap">
                    <Table hover responsive className="rental-table mb-0 align-middle">
                      <thead>
                        <tr>
                          <th>ID</th>
                          <th>Name</th>
                          <th>Email</th>
                          <th>Phone</th>
                          <th>City</th>
                          <th>Looking For</th>
                          <th>Joined</th>
                        </tr>
                      </thead>
                      <tbody>
                        {users.map((u) => (
                          <tr key={u.id}>
                            <td>{u.id}</td>
                            <td className="fw-bold">{u.name}</td>
                            <td>{u.email}</td>
                            <td>{u.phone ?? '-'}</td>
                            <td>{u.city ?? '-'}</td>
                            <td>{u.looking_for ?? '-'}</td>
                            <td>{u.createdAt ? new Date(u.createdAt).toLocaleDateString() : '-'}</td>
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

export default UsersList;
