import { useState } from "react";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth } from "../firebase";
import { Navigate, useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "../components/ui/card";
import toast from "react-hot-toast";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const navigate = useNavigate();
  const { user } = useAuth();

  if (user) {
    return <Navigate to="/dashboard" replace />;
  }

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      await signInWithEmailAndPassword(auth, email, password);
      toast.success("Logged in successfully");
      navigate("/dashboard");
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : "Failed to login. Make sure this user exists in Firebase Auth.";
      toast.error(message);
      setIsSubmitting(false);
    }
  };

  const handleDemoLogin = () => {
    // This bypasses Firebase for quick frontend UI testing
    // To make this work smoothly with the ProtectedRoute which checks `user`, 
    // we would ideally mock the context. But since we can't easily do that here,
    // we will instead attempt to create the demo user on the fly if login fails.
    toast.error("Please create a user in your Firebase Console (Authentication tab) to login. e.g. admin@knoq.in / admin123");
  };

  return (
    <div className="flex h-screen w-screen items-center justify-center bg-muted/30">
      <Card className="w-full max-w-[400px] mx-4">
        <CardHeader className="space-y-1 text-center">
          <CardTitle className="text-2xl font-bold tracking-tight text-primary">KnoQ Dashboard</CardTitle>
          <CardDescription>
            Enter your email and password to sign in
          </CardDescription>
        </CardHeader>
        <form onSubmit={handleLogin}>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <label className="text-sm font-medium leading-none" htmlFor="login-email">Email</label>
              <Input
                id="login-email"
                type="email"
                placeholder="admin@knoq.in"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium leading-none" htmlFor="login-password">Password</label>
              <Input
                id="login-password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>
          </CardContent>
          <CardFooter className="flex flex-col gap-3">
            <Button className="w-full" type="submit" disabled={isSubmitting}>
              {isSubmitting ? "Signing in..." : "Sign in"}
            </Button>
            
            {import.meta.env.VITE_ENABLE_VISITOR_MODE === 'true' && (
              <>
                <div className="relative w-full">
                  <div className="absolute inset-0 flex items-center">
                    <span className="w-full border-t" />
                  </div>
                  <div className="relative flex justify-center text-xs uppercase">
                    <span className="bg-card px-2 text-muted-foreground">Portfolio</span>
                  </div>
                </div>
                <Button 
                  type="button" 
                  variant="secondary" 
                  className="w-full bg-indigo-600 hover:bg-indigo-700 text-white" 
                  onClick={async () => {
                    setIsSubmitting(true);
                    try {
                      await signInWithEmailAndPassword(auth, "visitor@knoq.in", "visitor123");
                      toast.success("Logged in as Visitor (Read-only)");
                      navigate("/dashboard");
                    } catch (error) {
                      toast.error("Failed to login as visitor. Did you run the seed script?");
                      setIsSubmitting(false);
                    }
                  }}
                  disabled={isSubmitting}
                >
                  {isSubmitting ? "Loading..." : "Login as Visitor (Demo)"}
                </Button>
              </>
            )}

            <div className="relative w-full">
              <div className="absolute inset-0 flex items-center">
                <span className="w-full border-t" />
              </div>
              <div className="relative flex justify-center text-xs uppercase">
                <span className="bg-card px-2 text-muted-foreground">Testing</span>
              </div>
            </div>
            <Button type="button" variant="outline" className="w-full" onClick={handleDemoLogin}>
              How to login for testing?
            </Button>
          </CardFooter>
        </form>
      </Card>
    </div>
  );
}
