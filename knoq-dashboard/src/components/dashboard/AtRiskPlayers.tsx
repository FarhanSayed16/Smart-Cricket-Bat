import { Bell } from "lucide-react";
import { Button } from "../ui/button";
import { formatDistanceToNow } from "date-fns";

export interface AtRiskPlayer {
  id: string;
  name: string;
  lastSessionDate: string;
}

interface AtRiskPlayersProps {
  players: AtRiskPlayer[];
}

export function AtRiskPlayers({ players }: AtRiskPlayersProps) {
  if (players.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-[300px] text-muted-foreground text-sm">
        <div className="bg-green-500/10 p-3 rounded-full mb-3">
          <Bell className="h-6 w-6 text-green-500" />
        </div>
        <p>No at-risk players.</p>
        <p>Everyone has practiced recently!</p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {players.map((player) => (
        <div key={player.id} className="flex items-center justify-between p-3 border rounded-lg hover:bg-muted/50 transition-colors">
          <div>
            <p className="font-medium text-sm">{player.name}</p>
            <p className="text-xs text-destructive">
              Inactive for {formatDistanceToNow(new Date(player.lastSessionDate))}
            </p>
          </div>
          <Button variant="outline" size="sm" className="h-8 text-xs">
            Remind
          </Button>
        </div>
      ))}
    </div>
  );
}
