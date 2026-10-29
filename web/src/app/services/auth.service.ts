import { HttpClient } from '@angular/common/http';
import { Injectable, computed, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { Observable, map } from 'rxjs';

import { LOGIN_URL } from '../api.config';
import { Session } from '../models/auth.model';

const STORAGE_KEY = 'consware.session';

/** Error de login ya traducido para mostrarlo en el formulario. */
export class LoginError extends Error {}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly router = inject(Router);
  private expiryTimer?: ReturnType<typeof setTimeout>;

  private readonly session = signal<Session | null>(null);

  readonly user = computed(() => this.session()?.user ?? null);
  readonly token = computed(() => this.session()?.token ?? null);
  readonly isLoggedIn = computed(() => this.session() !== null);
  readonly expiresAt = computed(() => {
    const session = this.session();
    return session ? new Date(session.expiresAtUtc) : null;
  });

  constructor() {
    // sessionStorage: la sesión no sobrevive al cierre del navegador y no se comparte entre pestañas.
    try {
      const raw = sessionStorage.getItem(STORAGE_KEY);
      if (raw) this.start(JSON.parse(raw) as Session);
    } catch {
      sessionStorage.removeItem(STORAGE_KEY);
    }
  }

  login(username: string, password: string): Observable<Session> {
    return this.http.post<Session>(LOGIN_URL, { username: username.trim(), password }).pipe(
      map((session) => {
        // El panel es exclusivo del Equipo de Finanzas; los empleados usan la app móvil.
        if (session.user.role !== 'Approver') {
          throw new LoginError(
            'Este panel es exclusivo para aprobadores. Registra tus gastos desde la app móvil.',
          );
        }
        this.start(session);
        return session;
      }),
    );
  }

  /** Cierra la sesión; `expired` lleva al login con el aviso de sesión vencida. */
  logout(expired = false): void {
    clearTimeout(this.expiryTimer);
    this.session.set(null);
    sessionStorage.removeItem(STORAGE_KEY);
    this.router.navigate(['/login'], expired ? { queryParams: { sesion: 'expirada' } } : {});
  }

  private start(session: Session): void {
    const remaining = new Date(session.expiresAtUtc).getTime() - Date.now();
    if (remaining <= 0) {
      sessionStorage.removeItem(STORAGE_KEY);
      return;
    }
    this.session.set(session);
    sessionStorage.setItem(STORAGE_KEY, JSON.stringify(session));

    // Cierra la sesión justo cuando el token vence, sin esperar a un 401.
    clearTimeout(this.expiryTimer);
    this.expiryTimer = setTimeout(() => this.logout(true), Math.min(remaining, 2_147_000_000));
  }
}
