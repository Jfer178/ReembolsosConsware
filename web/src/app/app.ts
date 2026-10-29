import { Component, computed, inject } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';

import { ReimbursementStore } from './services/reimbursement-store';
import { LogoMark } from './shared/logo';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, LogoMark],
  templateUrl: './app.html',
  styleUrl: './app.scss',
})
export class App {
  private readonly store = inject(ReimbursementStore);

  protected readonly pendingCount = computed(
    () => this.store.items().filter((item) => item.status === 'Pending').length,
  );
}
