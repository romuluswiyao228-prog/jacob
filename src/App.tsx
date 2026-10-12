import { lazy, Suspense } from "react";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { AuthProvider } from "@/lib/auth-context";
import { RequireAuth } from "@/components/RequireAuth";
import { RequireAdmin } from "@/components/RequireAdmin";

const LoginPage = lazy(() => import("@/routes/LoginPage"));
const SignUpPage = lazy(() => import("@/routes/SignUpPage"));
const ForgotPasswordPage = lazy(() => import("@/routes/ForgotPasswordPage"));
const ProfilePage = lazy(() => import("@/routes/ProfilePage"));

const AdminLoginPage = lazy(() => import("@/routes/admin/AdminLoginPage"));
const MfaSetupPage = lazy(() => import("@/routes/admin/MfaSetupPage"));
const AdminDashboardPage = lazy(() => import("@/routes/admin/AdminDashboardPage"));

const DesignSystemPage = lazy(() => import("@/routes/DesignSystemPage"));

function PageFallback() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-neutral-50">
      <p className="text-neutral-500">Chargement…</p>
    </div>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Suspense fallback={<PageFallback />}>
          <Routes>
            {/* Auth routes */}
            <Route path="/connexion" element={<LoginPage />} />
            <Route path="/inscription" element={<SignUpPage />} />
            <Route path="/mot-de-passe-oublie" element={<ForgotPasswordPage />} />

            {/* Protected client route */}
            <Route
              path="/compte"
              element={
                <RequireAuth>
                  <ProfilePage />
                </RequireAuth>
              }
            />

            {/* Admin routes */}
            <Route path="/admin/connexion" element={<AdminLoginPage />} />
            <Route path="/admin/mfa-setup" element={<MfaSetupPage />} />
            <Route
              path="/admin"
              element={
                <RequireAdmin>
                  <AdminDashboardPage />
                </RequireAdmin>
              }
            />

            {/* Placeholder home */}
            <Route path="/" element={<div className="min-h-screen bg-neutral-50" />} />

            {/* Design system — dev only */}
            {import.meta.env.DEV && (
              <Route path="/design-system" element={<DesignSystemPage />} />
            )}

            <Route path="*" element={<div className="min-h-screen bg-neutral-50" />} />
          </Routes>
        </Suspense>
      </BrowserRouter>
    </AuthProvider>
  );
}
