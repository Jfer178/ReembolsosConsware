import { Routes } from '@angular/router';

import { Approvals } from './features/approvals/approvals.component';

export const routes: Routes = [
  { path: '', component: Approvals, title: 'Panel de aprobación · Consware' },
  { path: '**', redirectTo: '' },
];
