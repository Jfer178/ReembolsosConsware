import { Component, computed, inject, signal } from '@angular/core';
import { Router } from '@angular/router';

import { Reimbursement } from '../models/reimbursement.model';
import { ReimbursementStore } from '../services/reimbursement-store';
import { formatCop, requestCode, timeAgo } from './format';

/** Barra superior de las páginas: contenido propio a la izquierda, notificaciones y equipo a la derecha. */
@Component({
  selector: 'app-topbar',
  templateUrl: './topbar.html',
  styleUrl: './topbar.scss',
  host: { '(document:keydown.escape)': 'menuOpen.set(false)' },
})
export class Topbar {
  protected readonly store = inject(ReimbursementStore);
  private readonly router = inject(Router);

  protected readonly menuOpen = signal(false);
  protected readonly count = computed(() => this.store.notifications().length);

  protected readonly code = requestCode;
  protected readonly formatCop = formatCop;
  protected readonly timeAgo = timeAgo;

  protected open(item: Reimbursement): void {
    this.menuOpen.set(false);
    this.router.navigate(['/'], { queryParams: { solicitud: item.id } });
  }
}
