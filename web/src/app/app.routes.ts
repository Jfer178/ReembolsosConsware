import { Routes } from '@angular/router';

import { Approvals } from './features/approvals/approvals.component';
import { Reports } from './features/reports/reports.component';

export const routes: Routes = [
  { path: '', component: Approvals, title: 'Panel de aprobación · Consware' },
  { path: 'reportes', component: Reports, title: 'Reportes · Consware' },
  { path: '**', redirectTo: '' },
];
