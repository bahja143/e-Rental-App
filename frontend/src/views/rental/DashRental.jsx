import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { Alert, Badge, Button, Col, Row, Spinner, Table } from 'react-bootstrap';
import Chart from 'react-apexcharts';
import { getAdminOverview } from '../../services/rentalApi';

const money = (value) => `$${Number(value || 0).toLocaleString()}`;

const DashRental = () => {
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState('');
  const [overview, setOverview] = useState(null);

  const loadOverview = useCallback(async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true);
    else setLoading(true);
    setError('');
    try {
      const res = await getAdminOverview({ months: 6, recentLimit: 8 });
      setOverview(res.data ?? null);
    } catch (err) {
      console.error(err);
      setError(err?.error || err?.message || 'Failed to load admin overview.');
      setOverview(null);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    loadOverview(false);
  }, [loadOverview]);

  const metrics = overview?.metrics ?? {};
  const finance = overview?.finances ?? {};
  const statuses = overview?.rentals?.statuses ?? {};
  const monthlyTrend = overview?.rentals?.monthlyTrend ?? [];
  const recentRentals = overview?.rentals?.recent ?? [];
  const topListings = overview?.topListings ?? [];

  const monthlyChartOptions = useMemo(
    () => ({
      chart: { type: 'area', toolbar: { show: false }, fontFamily: 'inherit' },
      colors: ['#1f4c6b', '#e7b904'],
      stroke: { curve: 'smooth', width: 3 },
      fill: {
        type: 'gradient',
        gradient: {
          shadeIntensity: 1,
          opacityFrom: 0.25,
          opacityTo: 0.03,
          stops: [0, 100],
        },
      },
      dataLabels: { enabled: false },
      xaxis: { categories: monthlyTrend.map((item) => item.month) },
      yaxis: [
        { title: { text: 'Revenue' }, labels: { formatter: (value) => `$${Math.round(value)}` } },
        { opposite: true, title: { text: 'Rentals' } },
      ],
      grid: { borderColor: '#edf0f5', strokeDashArray: 4 },
      legend: { position: 'top', horizontalAlign: 'right' },
    }),
    [monthlyTrend]
  );

  const monthlyChartSeries = useMemo(
    () => [
      {
        name: 'Revenue',
        type: 'area',
        data: monthlyTrend.map((item) => Number(item.revenue || 0)),
      },
      {
        name: 'Rentals',
        type: 'line',
        data: monthlyTrend.map((item) => Number(item.rentals || 0)),
      },
    ],
    [monthlyTrend]
  );

  if (loading) {
    return (
      <Row>
        <Col className="text-center py-5">
          <Spinner animation="border" style={{ color: '#e7b904' }} />
        </Col>
      </Row>
    );
  }

  return (
    <div className="rental-page advanced-dashboard-shell">
      <div className="advanced-hero">
        <div>
          <h3 className="advanced-hero-title">Back Office Overview</h3>
          <p className="advanced-hero-subtitle">Listings, rentals, finance, and operations in one admin snapshot.</p>
        </div>
        <div className="advanced-hero-actions d-flex gap-2">
          <Link to="/app/rental/reports" className="btn btn-outline-brand btn-sm">
            Open Reports
          </Link>
          <Button size="sm" onClick={() => loadOverview(true)} disabled={refreshing}>
            {refreshing ? 'Refreshing...' : 'Refresh'}
          </Button>
        </div>
      </div>

      {error && <Alert variant="danger">{error}</Alert>}

      <Row className="g-4 mb-1">
        <Col xl={3} md={6}>
          <div className="metric-tile">
            <div className="metric-icon">
              <i className="feather icon-map-pin" />
            </div>
            <div>
              <div className="metric-label">Listings</div>
              <div className="metric-value">{metrics.listings ?? 0}</div>
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
              <div className="metric-value">{metrics.rentals ?? 0}</div>
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
              <div className="metric-value">{metrics.users ?? 0}</div>
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
              <div className="metric-value">{money(metrics.grossRevenue)}</div>
            </div>
          </div>
        </Col>
      </Row>

      <Row className="g-4 mb-1">
        <Col lg={8}>
          <div className="advanced-panel">
            <div className="advanced-panel-header">
              <h5>
                <i className="feather icon-trending-up me-2" />
                Revenue Trend
              </h5>
            </div>
            {monthlyTrend.length === 0 ? (
              <div className="text-muted">No rental history available yet.</div>
            ) : (
              <Chart options={monthlyChartOptions} series={monthlyChartSeries} type="line" height={320} />
            )}
          </div>
        </Col>
        <Col lg={4}>
          <div className="advanced-panel h-100">
            <div className="advanced-panel-header">
              <h5>
                <i className="feather icon-activity me-2" />
                Operations Pulse
              </h5>
            </div>
            <div className="metric-inline">
              <span>Platform Revenue</span>
              <strong>{money(finance.platformRevenue)}</strong>
            </div>
            <div className="metric-inline">
              <span>Pending Rentals</span>
              <strong>{statuses.pending ?? 0}</strong>
            </div>
            <div className="metric-inline">
              <span>Confirmed Rentals</span>
              <strong>{statuses.confirmed ?? 0}</strong>
            </div>
            <div className="metric-inline">
              <span>Completed Rentals</span>
              <strong>{statuses.completed ?? 0}</strong>
            </div>
            <div className="metric-inline">
              <span>Cancelled Rentals</span>
              <strong>{statuses.cancelled ?? 0}</strong>
            </div>
            <div className="metric-inline">
              <span>Pending Withdrawals</span>
              <strong>{metrics.pendingWithdrawals ?? 0}</strong>
            </div>
            <div className="metric-inline">
              <span>Active Coupons</span>
              <strong>{metrics.activeCoupons ?? 0}</strong>
            </div>
            <div className="metric-inline mb-0">
              <span>Active Promotions</span>
              <strong>{metrics.activePromotions ?? 0}</strong>
            </div>
          </div>
        </Col>
      </Row>

      <Row className="g-4 mb-1">
        <Col xl={5}>
          <div className="advanced-panel h-100">
            <div className="advanced-panel-header">
              <h5>
                <i className="feather icon-award me-2" />
                Top Listings
              </h5>
              <Link to="/app/rental/listings" className="btn btn-sm btn-outline-brand">
                Manage listings
              </Link>
            </div>
            {topListings.length === 0 ? (
              <div className="text-muted">No listing performance data yet.</div>
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
                  {topListings.map((item) => (
                    <tr key={item.listingId}>
                      <td>{item.title}</td>
                      <td>{item.rentals}</td>
                      <td className="fw-bold text-brand-primary">{money(item.revenue)}</td>
                    </tr>
                  ))}
                </tbody>
              </Table>
            )}
          </div>
        </Col>
        <Col xl={7}>
          <div className="advanced-panel h-100">
            <div className="advanced-panel-header">
              <h5>
                <i className="feather icon-clock me-2" />
                Recent Rentals
              </h5>
              <Link to="/app/rental/rentals" className="btn btn-sm btn-primary">
                Review rentals
              </Link>
            </div>
            {recentRentals.length === 0 ? (
              <div className="text-muted">No recent rentals yet.</div>
            ) : (
              <Table hover responsive className="rental-table mb-0 align-middle">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Listing</th>
                    <th>Renter</th>
                    <th>Status</th>
                    <th>Total</th>
                  </tr>
                </thead>
                <tbody>
                  {recentRentals.map((item) => (
                    <tr key={item.id}>
                      <td>{item.id}</td>
                      <td>{item.listing?.title ?? '-'}</td>
                      <td>{item.renter?.name ?? '-'}</td>
                      <td>
                        <Badge bg={item.status === 'confirmed' ? 'success' : item.status === 'cancelled' ? 'danger' : 'secondary'}>
                          {item.status}
                        </Badge>
                      </td>
                      <td>{money(item.total)}</td>
                    </tr>
                  ))}
                </tbody>
              </Table>
            )}
          </div>
        </Col>
      </Row>
    </div>
  );
};

export default DashRental;
