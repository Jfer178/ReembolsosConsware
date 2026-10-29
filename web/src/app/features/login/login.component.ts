import { HttpErrorResponse } from '@angular/common/http';
import { Component, inject, signal } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { ActivatedRoute, Router } from '@angular/router';
import { finalize, map } from 'rxjs';

import { AuthService, LoginError } from '../../services/auth.service';
import { apiErrorMessage } from '../../services/reimbursement.service';
import { LogoMark } from '../../shared/logo';

@Component({
  selector: 'app-login',
  imports: [LogoMark],
  templateUrl: './login.component.html',
  styleUrl: './login.component.scss',
})
export class Login {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);

  protected readonly username = signal('');
  protected readonly password = signal('');
  protected readonly showPassword = signal(false);
  protected readonly submitting = signal(false);
  protected readonly error = signal<string | null>(null);
  protected readonly touched = signal(false);

  protected readonly expiredNotice = toSignal(
    this.route.queryParamMap.pipe(map((params) => params.get('sesion') === 'expirada')),
    { initialValue: false },
  );

  protected onInput(field: 'username' | 'password', event: Event): void {
    this[field].set((event.target as HTMLInputElement).value);
    this.error.set(null);
  }

  protected submit(event: Event): void {
    event.preventDefault();
    if (this.submitting()) return;
    this.touched.set(true);
    if (!this.username().trim() || !this.password()) return;

    this.submitting.set(true);
    this.error.set(null);
    this.auth
      .login(this.username(), this.password())
      .pipe(finalize(() => this.submitting.set(false)))
      .subscribe({
        next: () => {
          const back = this.route.snapshot.queryParamMap.get('volver');
          // Solo rutas internas, para no redirigir a sitios externos.
          this.router.navigateByUrl(back?.startsWith('/') && !back.startsWith('//') ? back : '/');
        },
        error: (err: unknown) => {
          this.password.set('');
          this.error.set(this.messageFor(err));
        },
      });
  }

  private messageFor(err: unknown): string {
    if (err instanceof LoginError) return err.message;
    if (err instanceof HttpErrorResponse && err.status === 429) {
      return 'Demasiados intentos. Espera un minuto antes de volver a intentarlo.';
    }
    return apiErrorMessage(err);
  }
}
