import axios from "axios";
import { auth } from "../firebase";
import toast from "react-hot-toast";

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || "http://localhost:3000",
});

api.interceptors.request.use(async (config) => {
  if (auth.currentUser) {
    const token = await auth.currentUser.getIdToken();
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
}, (error) => {
  return Promise.reject(error);
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    // Handle 403 Forbidden (Visitor Mode Read-only)
    if (error.response?.status === 403) {
      toast.error(error.response.data?.message || "Visitor mode: Modifications are disabled.");
    }
    
    // Handle 401 Unauthorized globally if needed (e.g., force logout)
    if (error.response?.status === 401) {
      auth.signOut();
      window.location.href = "/login";
    }
    return Promise.reject(error);
  }
);

export default api;
