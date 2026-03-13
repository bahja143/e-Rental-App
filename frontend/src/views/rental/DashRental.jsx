import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { Row, Col, Table, Spinner, Form, Button } from 'react-bootstrap';
import Chart from 'react-apexcharts';
import { getListings, getListingRentals, getUsers, getCompanyEarningsSummary } from '../../services/rentalApi';

const formatMoney = (value) => `$${Number(value || 0).toLocaleString()}`;

const parseDate = (value) => {
  if (!value) return null;
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? null : d;
};

const STATUS_OPTIONS = ['', 'pending', 'confirmed', 'cancelled', 'completed'];

const DashRental = () => {
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState('');

  const [statusFilter, setStatusFilter] = useState('');
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');

  const [listings, setListings] = useState([]);
  const [rentals, setRentals] = useState([]);
  const [stats, setStats] = useState({ listings: 0, rentals: 0, users: 0, earnings: 0 });
  const [earningsSummary, setEarningsSummary] = useState(null);

  const loadDashboard = useCallback(
    async (isRefresh = false) => {
      if (isRefresh) setRefreshing(true);
      else setLoading(true);
      setError('');

      const rentalParams = { limit: 400, page: 1 };
      if (statusFilter) rentalParams.status = statusFilter;

      const [listingsRes, rentalsRes, usersRes, earningsRes] = await Promise.allSettled([
        getListings({ limit: 300, page: 1 }),
        getListingRentals(rentalParams),
        getUsers({ limit: 1, page: 1 }),
        getCompanyEarningsSummary()
      ]);

      const listingRows = listingsRes.status === 'fulfilled' ? listingsRes.value.data?.data ?? [] : [];
      const rentalRows = rentalsRes.status === 'fulfilled' ? rentalsRes.value.data?.data ?? [] : [];
      const usersTotal = usersRes.status === 'fulfilled' ? usersRes.value.data?.pagination?.totalItems ?? 0 : 0;

      if (listingsRes.status === 'rejected' && rentalsRes.status === 'rejected' && usersRes.status === 'rejected') {
        setError('Unable to load dashboard data from backend.');
      }

      setListings(listingRows);
      setRentals(rentalRows);
      setEarningsSummary(earningsRes.status === 'fulfilled' ? earningsRes.value.data ?? null : null);

      const totalListings =
        listingsRes.status === 'fulfilled' ? listingsRes.value.data?.pagination?.total ?? listingRows.length : listingRows.length;
      const totalRentals =
        rentalsRes.status === 'fulfilled' ? rentalsRes.value.data?.pagination?.totalItems ?? rentalRows.length : rentalRows.length;
      const grossRevenue = rentalRows.reduce((sum, r) => sum + Number(r.total ?? r.subtotal ?? 0), 0);
      setStats({ listings: totalListings, rentals: totalRentals, users: usersTotal, earnings: grossRevenue });

      setLoading(false);
      setRefreshing(false);
    },
    [statusFilter]
  );

  useEffect(() => {
    loadDashboard(false);
  }, [loadDashboard]);

  const filteredRentals = useMemo(
    () =>
      rentals.filter((r) => {
        const date = parseDate(r.start_date || r.createdAt);
        if (!date && (fromDate || toDate)) return false;
        if (fromDate && date && date < new Date(fromDate)) return false;
        if (toDate && date) {
          const to = new Date(toDate);
          to.setHours(23, 59, 59, 999);
          if (date > to) return false;
        }
        return true;
      }),
    [rentals, fromDate, toDate]
  );

  const status = useMemo(() => {
    const pending = filteredRentals.filter((r) => r.status === 'pending').length;
    const confirmed = filteredRentals.filter((r) => r.status === 'confirmed').length;
    const completed = filteredRentals.filter((r) => r.status === 'completed').length;
    const cancelled = filteredRentals.filter((r) => r.status === 'cancelled').length;
    return { pending, confirmed, completed, cancelled };
  }, [filteredRentals]);

  const occupancy = listings.length > 0 ? Math.min(100, Math.round((filteredRentals.length / listings.length) * 100)) : 0;
  const conversion = stats.users > 0 ? Math.min(100, Math.round((filteredRentals.length / stats.users) * 100)) : 0;
  const completionRate = filteredRentals.length > 0 ? Math.round((status.completed / filteredRentals.length) * 100) : 0;
  const cancellationRate = filteredRentals.length > 0 ? Math.round((status.cancelled / filteredRentals.length) * 100) : 0;
  const avgOrderValue = filteredRentals.length > 0 ? Math.round(stats.earnings / filteredRentals.length) : 0;

  const kpiChartOptions = useMemo(
    () => ({
      chart: { type: 'bar', toolbar: { show: false }, fontFamily: 'inherit' },
      plotOptions: { bar: { borderRadius: 4, horizontal: false, columnWidth: '55%' } },
      dataLabels: { enabled: true, formatter: (v) => `${v}%` },
      xaxis: { categories: ['Occupancy', 'Conversion', 'Completion', 'Cancellation'] },
      yaxis: { max: 100, tickAmount: 5, labels: { formatter: (v) => `${v}%` } },
      colors: ['#e7b904', '#2c6e97', '#28a745', '#dc3545'],
      grid: { borderColor: '#eee', strokeDashArray: 3, xaxis: { lines: { show: false } } },
      tooltip: { y: { formatter: (v) => `${v}%` } }
    }),
    []
  );

  const kpiChartSeries = useMemo(
    () => [{ name: 'KPI %', data: [occupancy, conversion, completionRate, cancellationRate] }],
    [occupancy, conversion, completionRate, cancellationRate]
  );

  const statusChartOptions = useMemo(
    () => ({
      chart: { type: 'donut', fontFamily: 'inherit' },
      labels: ['Pending', 'Confirmed', 'Completed', 'Cancelled'],
      colors: ['#ffc107', '#28a745', '#1f4c6b', '#dc3545'],
      legend: { position: 'bottom', horizontalAlign: 'center' },
      plotOptions: { pie: { donut: { size: '55%', labels: { show: true, total: { show: true, label: 'Rentals' } } } } },
      noData: { text: 'No rentals', align: 'center', verticalAlign: 'middle' }
    }),
    []
  );

  const statusChartSeries = useMemo(
    () => [status.pending, status.confirmed, status.completed, status.cancelled],
    [status.pending, status.confirmed, status.completed, status.cancelled]
  );

  const topListings = useMemo(() => {
    const map = new Map();
    filteredRentals.forEach((r) => {
      const name = r.listing?.title ?? `Listing ${r.list_id ?? '-'}`;
      const prev = map.get(name) ?? { count: 0, revenue: 0 };
      map.set(name, { count: prev.count + 1, revenue: prev.revenue + Number(r.total ?? r.subtotal ?? 0) });
    });
    return [...map.entries()]
      .map(([name, value]) => ({ name, ...value }))
      .sort((a, b) => b.revenue - a.revenue)
      .slice(0, 5);
  }, [filteredRentals]);

  const timeline = useMemo(() => {
    const months = new Map();
    filteredRentals.forEach((r) => {
      const date = parseDate(r.createdAt || r.start_date);
      if (!date) return;
      const key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
      months.set(key, (months.get(key) ?? 0) + 1);
    });
    return [...months.entries()]
      .map(([month, count]) => ({ month, count }))
      .sort((a, b) => (a.month < b.month ? -1 : 1))
      .slice(-12);
  }, [filteredRentals]);

  const exportCsv = () => {
    if (filteredRentals.length === 0) return;
    try {
      const headers = ['id', 'listing', 'renter', 'status', 'start_date', 'end_date', 'total'];
      const lines = filteredRentals.map((r) =>
        [
          r.id,
          r.listing?.title ?? r.list_id ?? '',
          r.renter?.name ?? r.renter_id ?? '',
          r.status ?? '',
          r.start_date ?? '',
          r.end_date ?? '',
          r.total ?? r.subtotal ?? ''
        ]
          .map((x) => String(x).replace(/[,]/g, ' '))
          .join(',')
      );
      const csv = [headers.join(','), ...lines].join('\n');
      const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `dashboard-rentals-${new Date().toISOString().slice(0, 10)}.csv`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);
    } catch (err) {
      console.error('Export failed:', err);
      alert('Export failed. Please try again.');
    }
  };

  if (loading) {
    return (
      <Row>
        <Col className="text-center py-5">
          <Spinner animation="border" />
        </Col>
      </Row>
    );
  }

  return (
    <div className="rental-page advanced-dashboard-shell">
      <div className="advanced-hero">
        <div>
          <h3 className="advanced-hero-title">Executive Rental Dashboard</h3>
          <p className="advanced-hero-subtitle">One powerful command center for KPI, performance and financial visibility.</p>
        </div>
        <div className="advanced-hero-actions">
          <Button variant="outline-brand" size="sm" onClick={exportCsv} disabled={filteredRentals.length === 0}>
            <i className="feather icon-download me-1" />
            Export
          </Button>
          <Button size="sm" onClick={() => loadDashboard(true)} disabled={refreshing}>
            <i className="feather icon-refresh-cw me-1" />
            {refreshing ? 'Refreshing...' : 'Refresh'}
          </Button>
        </div>
      </div>

      <Row className="g-4 mb-1">
        <Col xl={3} md={6}>
          <div className="metric-tile">
            <div className="metric-icon">
              <i className="feather icon-map-pin" />
            </div>
            <div>
              <div className="metric-label">Listings</div>
              <div className="metric-value">{stats.listings}</div>
            </div>
          </div>
        </Col>
        <Col xl={3} md={6}>
          <div className="metric-tile">
            <div className="metric-icon">
              <i className="feather icon-calendar" />
            </div>
            <div>
              <div className="metric-label">Rentals</div>
              <div className="metric-value">{stats.rentals}</div>
            </div>
          </div>
        </Col>
        <Col xl={3} md={6}>
          <div className="metric-tile">
            <div className="metric-icon">
              <i className="feather icon-users" />
            </div>
            <div>
              <div className="metric-label">Users</div>
              <div className="metric-value">{stats.users}</div>
            </div>
          </div>
        </Col>
        <Col xl={3} md={6}>
          <div className="metric-tile metric-tile-gold">
            <div className="metric-icon">
              <i className="feather icon-dollar-sign" />
            </div>
            <div>
              <div className="metric-label">Gross Revenue</div>
              <div className="metric-value">{formatMoney(stats.earnings)}</div>
            </div>
          </div>
        </Col>
      </Row>

      <div className="advanced-panel">
        <div className="advanced-panel-header">
          <h5>Performance</h5>
          <div className="d-flex gap-2 flex-wrap">
            <Form.Select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} style={{ width: 140 }}>
              {STATUS_OPTIONS.map((s) => (
                <option key={s || 'all'} value={s}>
                  {s || 'All statuses'}
                </option>
              ))}
            </Form.Select>
            <Form.Control type="date" value={fromDate} onChange={(e) => setFromDate(e.target.value)} style={{ width: 145 }} />
            <Form.Control type="date" value={toDate} onChange={(e) => setToDate(e.target.value)} style={{ width: 145 }} />
          </div>
        </div>
        {error && <div className="text-danger mb-2">{error}</div>}
        <Row className="g-4">
          <Col lg={7}>
            <div className="perf-chart-box">
              <h6>KPI Metrics (%)</h6>
              <Chart options={kpiChartOptions} series={kpiChartSeries} type="bar" height={240} />
            </div>
          </Col>
          <Col lg={5}>
            <div className="perf-chart-box">
              <h6>Rental Status</h6>
              <Chart options={statusChartOptions} series={statusChartSeries} type="donut" height={240} />
            </div>
          </Col>
        </Row>
        <div className="perf-footer mt-3">
          <span>Avg Order Value: <strong>{formatMoney(avgOrderValue)}</strong></span>
          <span className="ms-3">Earnings: <strong className="text-brand-primary">{formatMoney(earningsSummary?.total_earnings)}</strong></span>
        </div>
      </div>

      <Row className="g-4 mb-1">
        <Col xl={6}>
          <div className="advanced-panel h-100">
            <div className="advanced-panel-header">
              <h5>
                <i className="feather icon-award me-2" />
                Top Performing Listings
              </h5>
            </div>
            {topListings.length === 0 ? (
              <div className="text-muted">No listing performance data in current filters.</div>
            ) : (
              <Table hover responsive className="rental-table mb-0">
                <thead>
                  <tr>
                    <th>Listing</th>
                    <th>Rentals</th>
                    <th>Revenue</th>
                  </tr>
                </thead>
                <tbody>
                  {topListings.map((row) => (
                    <tr key={row.name}>
                      <td>{row.name}</td>
                      <td>{row.count}</td>
                      <td className="fw-bold text-brand-primary">{formatMoney(row.revenue)}</td>
                    </tr>
                  ))}
                </tbody>
              </Table>
            )}
          </div>
        </Col>
        <Col xl={6}>
          <div className="advanced-panel h-100">
            <div className="advanced-panel-header">
              <h5>
                <i className="feather icon-bar-chart-2 me-2" />
                12-Month Activity
              </h5>
            </div>
            {timeline.length === 0 ? (
              <div className="text-muted">No monthly activity available.</div>
            ) : (
              <Table hover responsive className="rental-table mb-0">
                <thead>
                  <tr>
                    <th>Month</th>
                    <th>Rentals</th>
                  </tr>
                </thead>
                <tbody>
                  {timeline.map((m) => (
                    <tr key={m.month}>
                      <td>{m.month}</td>
                      <td>{m.count}</td>
                    </tr>
                  ))}
                </tbody>
              </Table>
            )}
          </div>
        </Col>
      </Row>

      <div className="advanced-panel mb-0">
        <div className="advanced-panel-header">
          <h5>
            <i className="feather icon-clock me-2" />
            Latest Rentals
          </h5>
          <div className="d-flex gap-2">
            <Link to="/app/rental/coupons" className="btn btn-sm btn-outline-brand">
              Coupons
            </Link>
            <Link to="/app/rental/promotions" className="btn btn-sm btn-outline-brand">
              Promotions
            </Link>
            <Link to="/app/rental/rentals" className="btn btn-sm btn-primary">
              View all
            </Link>
          </div>
        </div>
        {filteredRentals.length === 0 ? (
          <div className="text-muted">No rentals in selected filters.</div>
        ) : (
          <Table hover responsive className="rental-table mb-0">
            <thead>
              <tr>
                <th>ID</th>
                <th>Listing</th>
                <th>Renter</th>
                <th>Status</th>
                <th>Dates</th>
                <th>Total</th>
              </tr>
            </thead>
            <tbody>
              {filteredRentals.slice(0, 20).map((r) => (
                <tr key={r.id}>
                  <td>{r.id}</td>
                  <td>{r.listing?.title ?? r.list_id}</td>
                  <td>{r.renter?.name ?? r.renter_id}</td>
                  <td>
                    <span
                      className={`badge bg-${r.status === 'confirmed' ? 'success' : r.status === 'cancelled' ? 'danger' : 'secondary'}`}
                    >
                      {r.status}
                    </span>
                  </td>
                  <td>
                    {(parseDate(r.start_date)?.toLocaleDateString() || '-') + ' - ' + (parseDate(r.end_date)?.toLocaleDateString() || '-')}
                  </td>
                  <td>{formatMoney(r.total ?? r.subtotal)}</td>
                </tr>
              ))}
            </tbody>
          </Table>
        )}
      </div>
    </div>
  );
};

export default DashRental;
