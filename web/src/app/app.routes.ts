import { Routes } from '@angular/router';

import { Approvals } from './features/approvals/approvals.component';
import { Login } from './features/login/login.component';
import { Reports } from './features/reports/reports.component';
import { Shell } from './layout/shell';
import { authGuard, guestGuard } from './services/auth.guards';

export const routes: Routes = [
  { path: 'login', component: Login, canActivate: [guestGuard], title: 'Iniciar sesión · Consware' },
  {
    path: '',
    component: Shell,
    canActivate: [authGuard],
    children: [
      { path: '', component: Approvals, title: 'Panel de aprobación · Consware' },
      { path: 'reportes', component: Reports, title: 'Reportes · Consware' },
    ],
  },
  { path: '**', redirectTo: '' },
];
