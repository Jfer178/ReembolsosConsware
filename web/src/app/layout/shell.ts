import { Component, DestroyRef, computed, inject } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';

import { ReimbursementStore } from '../services/reimbursement-store';
import { LogoMark } from '../shared/logo';

/** Estructura del panel con sesión: barra lateral y contenido. Mientras existe, la lista se sincroniza. */
@Component({
  selector: 'app-shell',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, LogoMark],
  templateUrl: './shell.html',
  styleUrl: './shell.scss',
})
export class Shell {
  private readonly store = inject(ReimbursementStore);

  protected readonly pendingCount = computed(
    () => this.store.items().filter((item) => item.status === 'Pending').length,
  );

  constructor() {
    this.store.start();
    // Al salir del panel (cerrar sesión o sesión vencida) se detiene la sincronización y se borran los datos.
    inject(DestroyRef).onDestroy(() => this.store.stop());
  }
}
