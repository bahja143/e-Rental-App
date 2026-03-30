import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Alert, Badge, Col, Row, Spinner, Table } from 'react-bootstrap';
import Chart from 'react-apexcharts';
import { getAdminOverview, getCompanyEarnings, getWithdrawBalances } from '../../services/rentalApi';

const money = (value) => `$${Number(value || 0).toLocaleString()}`;

const ReportsHub = () => {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [overview, setOverview] = useState(null);
  const [earnings, setEarnings] = useState([]);
  const [withdrawals, setWithdrawals] = useState([]);

  const loadData = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const [overviewRes, earningsRes, withdrawalRes] = await Promise.all([
        getAdminOverview({ months: 12, recentLimit: 12 }),
        getCompanyEarnings({ limit: 8, page: 1 }),
        getWithdrawBalances({ limit: 8, page: 1, status: 'requested' }),
      ]);
      setOverview(overviewRes.data ?? null);
      setEarnings(earningsRes.data?.data ?? []);
      setWithdrawals(withdrawalRes.data?.data ?? []);
    } catch (err) {
      console.error(err);
      setError(err?.error || err?.message || 'Failed to load reports.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const monthlyTrend = overview?.rentals?.monthlyTrend ?? [];
  const finances = overview?.finances ?? {};
  const metrics = overview?.metrics ?? {};
  const topListings = overview?.topListings ?? [];

  const revenueChartOptions = useMemo(
    () => ({
      chart: { type: 'bar', toolbar: { show: false }, fontFamily: 'inherit' },
      colors: ['#1f4c6b', '#e7b904'],
      plotOptions: { bar: { borderRadius: 6, columnWidth: '45%' } },
      dataLabels: { enabled: false },
      xaxis: { categories: monthlyTrend.map((item) => item.month) },
      yaxis: { labels: { formatter: (value) => `$${Math.round(value)}` } },
      grid: { borderColor: '#edf0f5', strokeDashArray: 4 },
      legend: { position: 'top', horizontalAlign: 'right' },
    }),
    [monthlyTrend]
  );

  const revenueChartSeries = useMemo(
    () => [
      {
        name: 'Revenue',
        data: monthlyTrend.map((item) => Number(item.revenue || 0)),
      },
      {
        name: 'Rentals',
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
    <div className="rental-page">
      <div className="advanced-panel mb-4">
        <div className="advanced-panel-header">
          <h5>
            <i className="feather icon-bar-chart-2 me-2" />
            Reports & Analytics
          </h5>
        </div>
        <p className="text-muted mb-0">A focused admin reporting surface backed by one overview API plus finance and withdrawal queues.</p>
      </div>

      {error && <Alert variant="danger">{error}</Alert>}

      <Row className="g-4 mb-1">
        <Col md={4}>
          <div className="analytics-metric-box">
            <div className="metric-title">Platform Revenue</div>
            <div className="metric-value">{money(finances.platformRevenue)}</div>
            <div className="panel-note mt-2">Commission + listing earnings + promotion earnings.</div>
          </div>
        </Col>
        <Col md={4}>
          <div className="analytics-metric-box">
            <div className="metric-title">Pending Withdrawals</div>
            <div className="metric-value">{metrics.pendingWithdrawals ?? 0}</div>
            <div className="panel-note mt-2">Requested payouts waiting for review or processing.</div>
          </div>
        </Col>
        <Col md={4}>
          <div className="analytics-metric-box">
            <div className="metric-title">Active Promotions</div>
            <div className="metric-value">{metrics.activePromotions ?? 0}</div>
            <div className="panel-note mt-2">Live promotional packages currently influencing listings.</div>
          </div>
        </Col>
      </Row>

      <div className="advanced-panel mb-4">
        <div className="advanced-panel-header">
          <h5>
            <i className="feather icon-trending-up me-2" />
            12-Month Revenue & Rental Activity
          </h5>
        </div>
        {monthlyTrend.length === 0 ? (
          <div className="text-muted">No monthly analytics available yet.</div>
        ) : (
          <Chart options={revenueChartOptions} series={revenueChartSeries} type="bar" height={340} />
        )}
      </div>

      <Row className="g-4">
        <Col xl={6}>
          <div className="advanced-panel h-100">
            <div className="advanced-panel-header">
              <h5>
                <i className="feather icon-dollar-sign me-2" />
                Earnings Ledger
              </h5>
            </div>
            {earnings.length === 0 ? (
              <div className="text-muted">No earnings rows found.</div>
            ) : (
              <Table hover responsive className="rental-table mb-0">
                <thead>
                  <tr>
                    <th>Date</th>
                    <th>Commission</th>
                    <th>Listing</th>
                    <th>Promotion</th>
                  </tr>
                </thead>
                <tbody>
                  {earnings.map((row) => (
                    <tr key={row.id}>
                      <td>{row.date ? new Date(row.date).toLocaleDateString() : '-'}</td>
                      <td>{money(row.commission)}</td>
                      <td>{money(row.listing)}</td>
                      <td>{money(row.promotion)}</td>
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
                <i className="feather icon-credit-card me-2" />
                Withdrawal Queue
              </h5>
            </div>
            {withdrawals.length === 0 ? (
              <div className="text-muted">No requested withdrawals right now.</div>
            ) : (
              <Table hover responsive className="rental-table mb-0">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>User</th>
                    <th>Status</th>
                    <th>Amount</th>
                  </tr>
                </thead>
                <tbody>
                  {withdrawals.map((row) => (
                    <tr key={row.id}>
                      <td>{row.id}</td>
                      <td>{row.user?.name ?? row.user_id}</td>
                      <td>
                        <Badge bg={row.status === 'requested' ? 'warning' : 'secondary'}>{row.status}</Badge>
                      </td>
                      <td>{money(row.amount)}</td>
                    </tr>
                  ))}
                </tbody>
              </Table>
            )}
          </div>
        </Col>
      </Row>

      <div className="advanced-panel mt-4">
        <div className="advanced-panel-header">
          <h5>
            <i className="feather icon-award me-2" />
            Top Listings by Revenue
          </h5>
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
              {topListings.map((row) => (
                <tr key={row.listingId}>
                  <td>{row.title}</td>
                  <td>{row.rentals}</td>
                  <td className="fw-bold text-brand-primary">{money(row.revenue)}</td>
                </tr>
              ))}
            </tbody>
          </Table>
        )}
      </div>
    </div>
  );
};

export default ReportsHub;
