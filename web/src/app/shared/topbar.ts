import { Component, computed, inject, signal } from '@angular/core';
import { Router } from '@angular/router';

import { Reimbursement } from '../models/reimbursement.model';
import { AuthService } from '../services/auth.service';
import { ReimbursementStore } from '../services/reimbursement-store';
import { formatCop, initials, requestCode, timeAgo } from './format';

/** Barra superior de las páginas: contenido propio a la izquierda, notificaciones y cuenta a la derecha. */
@Component({
  selector: 'app-topbar',
  templateUrl: './topbar.html',
  styleUrl: './topbar.scss',
  host: { '(document:keydown.escape)': 'closeMenus()' },
})
export class Topbar {
  protected readonly store = inject(ReimbursementStore);
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);

  protected readonly menuOpen = signal(false);
  protected readonly accountOpen = signal(false);
  protected readonly count = computed(() => this.store.notifications().length);

  protected readonly user = this.auth.user;
  protected readonly initials = computed(() => initials(this.user()?.fullName ?? ''));
  protected readonly expiresLabel = computed(() => {
    const date = this.auth.expiresAt();
    return date
      ? `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`
      : '';
  });

  protected readonly code = requestCode;
  protected readonly formatCop = formatCop;
  protected readonly timeAgo = timeAgo;

  protected open(item: Reimbursement): void {
    this.menuOpen.set(false);
    this.router.navigate(['/'], { queryParams: { solicitud: item.id } });
  }

  protected closeMenus(): void {
    this.menuOpen.set(false);
    this.accountOpen.set(false);
  }

  protected logout(): void {
    this.accountOpen.set(false);
    this.auth.logout();
  }
}
