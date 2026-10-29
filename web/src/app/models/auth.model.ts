export type UserRole = 'Employee' | 'Approver';

export interface User {
  username: string;
  fullName: string;
  department: string;
  role: UserRole;
}

/** Respuesta de POST /api/auth/login. */
export interface Session {
  token: string;
  expiresAtUtc: string;
  user: User;
}
