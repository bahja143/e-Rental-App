import { FormattedMessage } from 'react-intl';

const menuItems = {
  items: [
    {
      id: 'rental-overview',
      title: <FormattedMessage id="rental-overview" />,
      type: 'group',
      icon: 'icon-rental',
      children: [
        {
          id: 'rental-dashboard',
          title: <FormattedMessage id="rental-dashboard" />,
          type: 'item',
          icon: 'feather icon-home',
          url: '/app/rental/dashboard'
        },
        {
          id: 'rental-profile',
          title: <FormattedMessage id="rental-profile" />,
          type: 'item',
          icon: 'feather icon-user',
          url: '/app/rental/profile',
          breadcrumbs: true,
          hideInMenu: true
        }
      ]
    },
    {
      id: 'rental-operations',
      title: <FormattedMessage id="rental-commercial" />,
      type: 'group',
      icon: 'icon-rental',
      children: [
        {
          id: 'rental-listings',
          title: <FormattedMessage id="rental-listings" />,
          type: 'item',
          icon: 'feather icon-map-pin',
          url: '/app/rental/listings'
        },
        {
          id: 'rental-rentals',
          title: <FormattedMessage id="rental-rentals" />,
          type: 'item',
          icon: 'feather icon-calendar',
          url: '/app/rental/rentals'
        },
        {
          id: 'rental-users',
          title: <FormattedMessage id="rental-users" />,
          type: 'item',
          icon: 'feather icon-users',
          url: '/app/rental/users'
        },
        {
          id: 'rental-catalog-hub',
          title: 'Catalog',
          type: 'item',
          icon: 'feather icon-grid',
          url: '/app/rental/catalog'
        },
        {
          id: 'rental-offers-hub',
          title: 'Offers',
          type: 'item',
          icon: 'feather icon-award',
          url: '/app/rental/offers'
        }
      ]
    },
    {
      id: 'rental-insights',
      title: <FormattedMessage id="rental-system" />,
      type: 'group',
      icon: 'icon-rental',
      children: [
        {
          id: 'rental-reports',
          title: 'Reports',
          type: 'item',
          icon: 'feather icon-bar-chart-2',
          url: '/app/rental/reports'
        }
      ]
    },
    {
      id: 'rental-system',
      title: <FormattedMessage id="rental-system" />,
      type: 'group',
      icon: 'icon-rental',
      children: [
        {
          id: 'rental-settings',
          title: <FormattedMessage id="rental-settings" />,
          type: 'item',
          icon: 'feather icon-settings',
          url: '/app/rental/settings'
        }
      ]
    }
  ]
};

export default menuItems;
