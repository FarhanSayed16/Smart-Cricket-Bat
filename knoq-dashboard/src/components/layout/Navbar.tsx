import { LogOut, User as UserIcon } from "lucide-react";
import { useAuth } from "../../auth/AuthContext";
import { auth } from "../../firebase";
import { Button } from "../ui/button";
import { useNavigate } from "react-router-dom";

export function Navbar() {
  const { dbUser } = useAuth();
  const navigate = useNavigate();

  const handleLogout = async () => {
    await auth.signOut();
    navigate("/login");
  };

  return (
    <header className="h-16 border-b bg-background flex items-center justify-end px-6">
      <div className="flex items-center gap-4">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-full bg-muted flex items-center justify-center">
            <UserIcon className="h-4 w-4 text-muted-foreground" />
          </div>
          <div className="hidden sm:block text-sm">
            <p className="font-medium leading-none">{dbUser?.display_name || "Admin"}</p>
            <p className="text-muted-foreground text-xs mt-0.5 capitalize">{dbUser?.role || "Loading..."}</p>
          </div>
        </div>
        <Button
          variant="ghost"
          size="sm"
          onClick={handleLogout}
          className="text-muted-foreground hover:text-foreground"
          title="Logout"
        >
          <LogOut className="h-4 w-4" />
        </Button>
      </div>
    </header>
  );
}
