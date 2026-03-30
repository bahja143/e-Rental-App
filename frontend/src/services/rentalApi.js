import axios from '../utils/authAxios';

const api = axios;

// Settings
export const getAppSettings = () => api.get('/settings');
export const updateAppSettings = (data) => api.patch('/settings', data);

// Auth
export const authLogin = (email, password, rememberMe = false) =>
  api.post('/auth/login', { email, password, rememberMe });
export const authMe = () => api.get('/auth/me');
export const authLogout = () => api.post('/auth/logout');
export const authUpdateProfile = (data) => api.patch('/auth/me', data);

// Listings
export const getListings = (params = {}) => api.get('/listings', { params });
export const getListingById = (id) => api.get(`/listings/${id}`);
export const createListing = (data) => api.post('/listings', data);
export const updateListing = (id, data) => api.put(`/listings/${id}`, data);
export const deleteListing = (id) => api.delete(`/listings/${id}`);

// Listing Rentals
export const getListingRentals = (params = {}) => api.get('/listing-rentals', { params });
export const getListingRentalById = (id) => api.get(`/listing-rentals/${id}`);
export const createListingRental = (data) => api.post('/listing-rentals', data);
export const updateListingRental = (id, data) => api.put(`/listing-rentals/${id}`, data);
export const deleteListingRental = (id) => api.delete(`/listing-rentals/${id}`);

// Users
export const getUsers = (params = {}) => api.get('/users', { params });
export const getUserById = (id) => api.get(`/users/${id}`);
export const createUser = (data) => api.post('/users', data);
export const updateUser = (id, data) => api.put(`/users/${id}`, data);
export const deleteUser = (id) => api.delete(`/users/${id}`);

// Notifications
export const getNotifications = (params = {}) => api.get('/notifications', { params });
export const createNotification = (data) => api.post('/notifications', data);
export const deleteNotification = (id) => api.delete(`/notifications/${id}`);

// Company earnings
export const getCompanyEarnings = (params = {}) => api.get('/company-earnings', { params });
export const getCompanyEarningsSummary = () => api.get('/company-earnings/summary');
export const getAdminOverview = (params = {}) => api.get('/admin/reports/overview', { params });

// Coupons
export const getCoupons = (params = {}) => api.get('/coupons', { params });
export const createCoupon = (data) => api.post('/coupons', data);
export const updateCoupon = (id, data) => api.put(`/coupons/${id}`, data);
export const deleteCoupon = (id) => api.delete(`/coupons/${id}`);

// Promotions
export const getPromotions = (params = {}) => api.get('/promotions', { params });
export const createPromotion = (data) => api.post('/promotions', data);
export const updatePromotion = (id, data) => api.put(`/promotions/${id}`, data);
export const deletePromotion = (id) => api.delete(`/promotions/${id}`);

// Promotion packs
export const getPromotionPacks = (params = {}) => api.get('/promotion-packs', { params });
export const createPromotionPack = (data) => api.post('/promotion-packs', data);
export const updatePromotionPack = (id, data) => api.put(`/promotion-packs/${id}`, data);
export const deletePromotionPack = (id) => api.delete(`/promotion-packs/${id}`);

// Listing packs
export const getListingPacks = (params = {}) => api.get('/listing-packs', { params });
export const createListingPack = (data) => api.post('/listing-packs', data);
export const updateListingPack = (id, data) => api.put(`/listing-packs/${id}`, data);
export const deleteListingPack = (id) => api.delete(`/listing-packs/${id}`);

// Property categories
export const getPropertyCategories = (params = {}) => api.get('/property-categories', { params });
export const createPropertyCategory = (data) => api.post('/property-categories', data);
export const updatePropertyCategory = (id, data) => api.put(`/property-categories/${id}`, data);
export const deletePropertyCategory = (id) => api.delete(`/property-categories/${id}`);

// Type listings
export const getTypeListings = (params = {}) => api.get('/type-listings', { params });
export const createTypeListing = (data) => api.post('/type-listings', data);
export const updateTypeListing = (id, data) => api.put(`/type-listings/${id}`, data);
export const deleteTypeListing = (id) => api.delete(`/type-listings/${id}`);

// Listing types for selectors
export const getListingTypes = (params = {}) => api.get('/listing-types', { params });

// Facilities
export const getFacilities = (params = {}) => api.get('/facilities', { params });
export const createFacility = (data) => api.post('/facilities', data);
export const updateFacility = (id, data) => api.put(`/facilities/${id}`, data);
export const deleteFacility = (id) => api.delete(`/facilities/${id}`);

// FAQs
export const getFaqs = (params = {}) => api.get('/faqs', { params });
export const createFaq = (data) => api.post('/faqs', data);
export const updateFaq = (id, data) => api.put(`/faqs/${id}`, data);
export const deleteFaq = (id) => api.delete(`/faqs/${id}`);

// Nearby places
export const getNearbyPlaces = (params = {}) => api.get('/nearby-places', { params });
export const createNearbyPlace = (data) => api.post('/nearby-places', data);
export const updateNearbyPlace = (id, data) => api.put(`/nearby-places/${id}`, data);
export const deleteNearbyPlace = (id) => api.delete(`/nearby-places/${id}`);

// Companies
export const getCompanies = (params = {}) => api.get('/companies', { params });
export const createCompany = (data) => api.post('/companies', data);
export const updateCompany = (id, data) => api.put(`/companies/${id}`, data);
export const deleteCompany = (id) => api.delete(`/companies/${id}`);

// User bank accounts
export const getUserBankAccounts = (params = {}) => api.get('/user-bank-accounts', { params });
export const createUserBankAccount = (data) => api.post('/user-bank-accounts', data);
export const updateUserBankAccount = (id, data) => api.put(`/user-bank-accounts/${id}`, data);
export const deleteUserBankAccount = (id) => api.delete(`/user-bank-accounts/${id}`);

// User devices
export const getUserDevices = (params = {}) => api.get('/user-devices', { params });
export const createUserDevice = (data) => api.post('/user-devices', data);
export const updateUserDevice = (id, data) => api.put(`/user-devices/${id}`, data);
export const deleteUserDevice = (id) => api.delete(`/user-devices/${id}`);

// Withdraw balances
export const getWithdrawBalances = (params = {}) => api.get('/withdraw-balances', { params });
export const createWithdrawBalance = (data) => api.post('/withdraw-balances', data);
export const updateWithdrawBalance = (id, data) => api.put(`/withdraw-balances/${id}`, data);
export const deleteWithdrawBalance = (id) => api.delete(`/withdraw-balances/${id}`);
