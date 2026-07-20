export interface User {
  id: string;
  firebase_uid: string;
  email: string;
  role: 'super' | 'admin' | 'coach' | 'player';
  name: string;
  academy_id?: string;
  is_academy_owner?: boolean;
  created_at: string;
}

export interface Player {
  id: string;
  user_id: string;
  academy_id: string | null;
  assigned_coach_id: string | null;
  date_of_birth: string | null;
  batting_style: string | null;
  playing_role: string | null;
  profile_picture_url: string | null;
}

export interface Academy {
  id: string;
  name: string;
  admin_id: string;
  city: string | null;
  state: string | null;
  logo_url: string | null;
  join_code: string;
  subscription_tier: string;
  max_players: number;
}
