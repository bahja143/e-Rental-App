import PropTypes from 'prop-types';
import { createContext, useEffect, useReducer } from 'react';

// third-party
import { Chance } from 'chance';
import { jwtDecode } from 'jwt-decode';

// reducer - state management
import { LOGIN, LOGOUT, UPDATE_USER } from '../store/actions';
import authReducer from '../store/accountReducer';

// project import
import Loader from '../components/Loader/Loader';
import axios from '../utils/authAxios';

const chance = new Chance();

// constant
const initialState = {
  isLoggedIn: false,
  isInitialized: false,
  user: null
};

const verifyToken = (serviceToken) => {
  if (!serviceToken) {
    return false;
  }
  const decoded = jwtDecode(serviceToken);
  /**
   * Property 'exp' does not exist on type '<T = unknown>(token: string, options?: JwtDecodeOptions | undefined) => T'.
   */
  return decoded.exp > Date.now() / 1000;
};

const STORAGE_KEY = 'serviceToken';

const setSession = (serviceToken, rememberMe = true) => {
  const storage = rememberMe ? localStorage : sessionStorage;
  if (serviceToken) {
    localStorage.removeItem(STORAGE_KEY);
    sessionStorage.removeItem(STORAGE_KEY);
    storage.setItem(STORAGE_KEY, serviceToken);
    axios.defaults.headers.common.Authorization = `Bearer ${serviceToken}`;
  } else {
    localStorage.removeItem(STORAGE_KEY);
    sessionStorage.removeItem(STORAGE_KEY);
    delete axios.defaults.headers.common.Authorization;
  }
};

const getStoredToken = () => localStorage.getItem(STORAGE_KEY) || sessionStorage.getItem(STORAGE_KEY);

// ==============================|| JWT CONTEXT & PROVIDER ||============================== //

const JWTContext = createContext(null);

export const JWTProvider = ({ children }) => {
  const [state, dispatch] = useReducer(authReducer, initialState);

  useEffect(() => {
    const init = async () => {
      try {
        const serviceToken = getStoredToken();
        if (serviceToken && verifyToken(serviceToken)) {
          setSession(serviceToken, true);
          const response = await axios.get('/auth/me');
          const { user } = response.data;
          dispatch({
            type: LOGIN,
            payload: {
              isLoggedIn: true,
              user
            }
          });
        } else {
          dispatch({
            type: LOGOUT
          });
        }
      } catch (err) {
        console.error(err);
        dispatch({
          type: LOGOUT
        });
      }
    };

    init();
  }, []);

  const login = async (email, password, rememberMe = false) => {
    const response = await axios.post('/auth/login', { email, password, rememberMe });
    const { user, tokens } = response.data;
    const accessToken = tokens?.accessToken;
    setSession(accessToken, rememberMe);
    dispatch({
      type: LOGIN,
      payload: {
        isLoggedIn: true,
        user
      }
    });
  };

  const register = async (email, password, firstName, lastName) => {
    // todo: this flow need to be recode as it not verified
    const id = chance.bb_pin();
    const response = await axios.post('/api/account/register', {
      id,
      email,
      password,
      firstName,
      lastName
    });
    let users = response.data;

    if (window.localStorage.getItem('users') !== undefined && window.localStorage.getItem('users') !== null) {
      const localUsers = window.localStorage.getItem('users');
      users = [
        ...JSON.parse(localUsers),
        {
          id,
          email,
          password,
          name: `${firstName} ${lastName}`
        }
      ];
    }

    window.localStorage.setItem('users', JSON.stringify(users));
  };

  const logout = () => {
    setSession(null, true);
    dispatch({ type: LOGOUT });
  };

  const resetPassword = async () => {};

  const updateProfile = async (profileData) => {
    const serviceToken = getStoredToken();
    if (!serviceToken) return;
    const response = await axios.patch('/auth/me', profileData);
    const { user } = response.data;
    if (user) {
      dispatch({ type: UPDATE_USER, payload: user });
    }
  };

  if (state.isInitialized !== undefined && !state.isInitialized) {
    return <Loader />;
  }

  return <JWTContext.Provider value={{ ...state, login, logout, register, resetPassword, updateProfile }}>{children}</JWTContext.Provider>;
};

JWTProvider.propTypes = {
  children: PropTypes.node
};

export default JWTContext;
