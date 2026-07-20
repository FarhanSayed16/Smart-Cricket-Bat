import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider } from "./auth/AuthContext";
import { ProtectedRoute } from "./components/layout/ProtectedRoute";
import { AppLayout } from "./components/layout/AppLayout";
import Login from "./pages/Login";
import Dashboard from "./pages/Dashboard";
import Players from "./pages/Players";
import Coaches from "./pages/Coaches";
import Devices from "./pages/Devices";
import SessionReplay from "./pages/SessionReplay";
import Analytics from "./pages/Analytics";
import AILab from "./pages/AILab";
import ClipTagging from "./pages/ClipTagging";
import Reports from "./pages/Reports";
import Notifications from "./pages/Notifications";
import Settings from "./pages/Settings";
import SuperAdmin from "./pages/SuperAdmin";
import { Toaster } from "react-hot-toast";

function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<Login />} />
          
          <Route element={<ProtectedRoute />}>
            <Route element={<AppLayout />}>
              <Route path="/" element={<Navigate to="/dashboard" replace />} />
              <Route path="/dashboard" element={<Dashboard />} />
              
              <Route path="/players" element={<Players />} />
              <Route path="/coaches" element={<Coaches />} />
              <Route path="/devices" element={<Devices />} />
              <Route path="/session-replay/:id" element={<SessionReplay />} />
              <Route path="/analytics" element={<Analytics />} />
              <Route path="/ai-lab" element={<AILab />} />
              <Route path="/ai-lab/tag/:clipId" element={<ClipTagging />} />
              <Route path="/reports" element={<Reports />} />
              <Route path="/notifications" element={<Notifications />} />
              <Route path="/settings" element={<Settings />} />
            </Route>
          </Route>
          
          <Route element={<ProtectedRoute allowedRoles={["super"]} />}>
            <Route element={<AppLayout />}>
              <Route path="/super-admin" element={<SuperAdmin />} />
            </Route>
          </Route>
          
          <Route path="/unauthorized" element={<div className="flex h-screen items-center justify-center text-muted-foreground">You do not have permission to access this page.</div>} />
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </Router>
      <Toaster position="top-right" />
    </AuthProvider>
  );
}

export default App;
