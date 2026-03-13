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
      id: 'rental-catalog',
      title: <FormattedMessage id="rental-catalog" />,
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
          id: 'rental-property-categories',
          title: <FormattedMessage id="rental-property-categories" />,
          type: 'item',
          icon: 'feather icon-grid',
          url: '/app/rental/property-categories'
        },
        {
          id: 'rental-type-listings',
          title: <FormattedMessage id="rental-type-listings" />,
          type: 'item',
          icon: 'feather icon-link',
          url: '/app/rental/type-listings'
        },
        {
          id: 'rental-facilities',
          title: <FormattedMessage id="rental-facilities" />,
          type: 'item',
          icon: 'feather icon-check-square',
          url: '/app/rental/facilities'
        },
        {
          id: 'rental-nearby-places',
          title: <FormattedMessage id="rental-nearby-places" />,
          type: 'item',
          icon: 'feather icon-map',
          url: '/app/rental/nearby-places'
        },
        {
          id: 'rental-faqs',
          title: <FormattedMessage id="rental-faqs" />,
          type: 'item',
          icon: 'feather icon-help-circle',
          url: '/app/rental/faqs'
        }
      ]
    },
    {
      id: 'rental-commercial',
      title: <FormattedMessage id="rental-commercial" />,
      type: 'group',
      icon: 'icon-rental',
      children: [
        {
          id: 'rental-rentals',
          title: <FormattedMessage id="rental-rentals" />,
          type: 'item',
          icon: 'feather icon-calendar',
          url: '/app/rental/rentals'
        },
        {
          id: 'rental-coupons',
          title: <FormattedMessage id="rental-coupons" />,
          type: 'item',
          icon: 'feather icon-tag',
          url: '/app/rental/coupons'
        },
        {
          id: 'rental-promotions',
          title: <FormattedMessage id="rental-promotions" />,
          type: 'item',
          icon: 'feather icon-award',
          url: '/app/rental/promotions'
        },
        {
          id: 'rental-promotion-packs',
          title: <FormattedMessage id="rental-promotion-packs" />,
          type: 'item',
          icon: 'feather icon-layers',
          url: '/app/rental/promotion-packs'
        },
        {
          id: 'rental-listing-packs',
          title: <FormattedMessage id="rental-listing-packs" />,
          type: 'item',
          icon: 'feather icon-package',
          url: '/app/rental/listing-packs'
        },
        {
          id: 'rental-withdraw-balances',
          title: <FormattedMessage id="rental-withdraw-balances" />,
          type: 'item',
          icon: 'feather icon-trending-down',
          url: '/app/rental/withdraw-balances'
        }
      ]
    },
    {
      id: 'rental-accounts',
      title: <FormattedMessage id="rental-accounts" />,
      type: 'group',
      icon: 'icon-rental',
      children: [
        {
          id: 'rental-users',
          title: <FormattedMessage id="rental-users" />,
          type: 'item',
          icon: 'feather icon-users',
          url: '/app/rental/users'
        },
        {
          id: 'rental-companies-accounts',
          title: <FormattedMessage id="rental-companies" />,
          type: 'item',
          icon: 'feather icon-briefcase',
          url: '/app/rental/companies'
        },
        {
          id: 'rental-user-bank-accounts-accounts',
          title: <FormattedMessage id="rental-user-bank-accounts" />,
          type: 'item',
          icon: 'feather icon-credit-card',
          url: '/app/rental/user-bank-accounts'
        },
        {
          id: 'rental-user-devices-accounts',
          title: <FormattedMessage id="rental-user-devices" />,
          type: 'item',
          icon: 'feather icon-smartphone',
          url: '/app/rental/user-devices'
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
