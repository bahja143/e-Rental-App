import React, { Suspense, Fragment, lazy } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';

import Loader from './components/Loader/Loader';
import AdminLayout from './layouts/AdminLayout';

import GuestGuard from './components/Auth/GuestGuard';
import AuthGuard from './components/Auth/AuthGuard';

import { BASE_URL } from './config/constant';

export const renderRoutes = (routes = []) => (
  <Suspense fallback={<Loader />}>
    <Routes>
      {routes.map((route, i) => {
        const Guard = route.guard || Fragment;
        const Layout = route.layout || Fragment;
        const Element = route.element;

        return (
          <Route
            key={i}
            path={route.path}
            element={
              <Guard>
                <Layout>{route.routes ? renderRoutes(route.routes) : <Element props={true} />}</Layout>
              </Guard>
            }
          />
        );
      })}
    </Routes>
  </Suspense>
);

const routes = [
  {
    exact: 'true',
    guard: GuestGuard,
    path: '/login',
    element: lazy(() => import('./views/auth/signin/SignIn1'))
  },
  {
    exact: 'true',
    guard: GuestGuard,
    path: '/signup',
    element: lazy(() => import('./views/auth/signup/SignUp1'))
  },
  {
    exact: 'true',
    guard: GuestGuard,
    path: '/reset-password',
    element: lazy(() => import('./views/auth/reset-password/ResetPassword1'))
  },
  {
    exact: 'true',
    path: '/404',
    element: lazy(() => import('./views/errors/NotFound404'))
  },
  {
    path: '*',
    layout: AdminLayout,
    guard: AuthGuard,
    routes: [
      {
        exact: 'true',
        path: '/app/rental/dashboard',
        element: lazy(() => import('./views/rental/DashRental'))
      },
      {
        exact: 'true',
        path: '/app/rental/catalog',
        element: lazy(() => import('./views/rental/CatalogHub'))
      },
      {
        exact: 'true',
        path: '/app/rental/offers',
        element: lazy(() => import('./views/rental/OffersHub'))
      },
      {
        exact: 'true',
        path: '/app/rental/reports',
        element: lazy(() => import('./views/rental/ReportsHub'))
      },
      {
        exact: 'true',
        path: '/app/rental/listings',
        element: lazy(() => import('./views/rental/ListingsList'))
      },
      {
        exact: 'true',
        path: '/app/rental/rentals',
        element: lazy(() => import('./views/rental/RentalsList'))
      },
      {
        exact: 'true',
        path: '/app/rental/users',
        element: lazy(() => import('./views/rental/UsersList'))
      },
      {
        exact: 'true',
        path: '/app/rental/coupons',
        element: lazy(() => import('./views/rental/CouponsManager'))
      },
      {
        exact: 'true',
        path: '/app/rental/promotions',
        element: lazy(() => import('./views/rental/PromotionsManager'))
      },
      {
        exact: 'true',
        path: '/app/rental/promotion-packs',
        element: lazy(() => import('./views/rental/PromotionPacksManager'))
      },
      {
        exact: 'true',
        path: '/app/rental/listing-packs',
        element: lazy(() => import('./views/rental/ListingPacksManager'))
      },
      {
        exact: 'true',
        path: '/app/rental/property-categories',
        element: lazy(() => import('./views/rental/PropertyCategoriesManager'))
      },
      {
        exact: 'true',
        path: '/app/rental/type-listings',
        element: lazy(() => import('./views/rental/TypeListingsManager'))
      },
      {
        exact: 'true',
        path: '/app/rental/facilities',
        element: lazy(() => import('./views/rental/FacilitiesManager'))
      },
      {
        exact: 'true',
        path: '/app/rental/faqs',
        element: lazy(() => import('./views/rental/FaqsManager'))
      },
      {
        exact: 'true',
        path: '/app/rental/nearby-places',
        element: lazy(() => import('./views/rental/NearbyPlacesManager'))
      },
      {
        exact: 'true',
        path: '/app/rental/profile',
        element: lazy(() => import('./views/rental/EditProfile'))
      },
      {
        exact: 'true',
        path: '/app/rental/settings',
        element: lazy(() => import('./views/rental/RentalSettings'))
      },
      {
        path: '*',
        exact: 'true',
        element: () => <Navigate to={BASE_URL} />
      }
    ]
  }
];

export default routes;
