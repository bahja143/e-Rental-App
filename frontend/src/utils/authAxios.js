// axios
import axios from 'axios';
const axiosServices = axios.create({ baseURL: import.meta.env.VITE_APP_API_URL || 'http://localhost:3000/api' });

// ==============================|| AXIOS SERVICES ||============================== //

axiosServices.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401 && !window.location.href.includes('/login')) {
      window.location.pathname = '/login';
    }
    return Promise.reject(error.response?.data || error.message || 'Wrong Services');
  }
);

export default axiosServices;
