import { DestroyRef, Injectable, inject, signal } from '@angular/core';
import { Observable, Subscription, finalize, tap } from 'rxjs';

import { Reimbursement } from '../models/reimbursement.model';
import { ReimbursementService, apiErrorMessage } from './reimbursement.service';

/**
 * Estado compartido del panel: mantiene la lista sincronizada con la API consultándola
 * periódicamente (solo con la pestaña visible) y detecta las solicitudes que llegan nuevas.
 */
@Injectable({ providedIn: 'root' })
export class ReimbursementStore {
  static readonly refreshIntervalMs = 10_000;

  private readonly api = inject(ReimbursementService);
  private knownIds: Set<number> | null = null;
  private inFlight?: Subscription;

  readonly items = signal<Reimbursement[]>([]);
  /** Solo la primera carga; las actualizaciones posteriores no muestran esqueletos. */
  readonly loading = signal(true);
  readonly refreshing = signal(false);
  readonly error = signal<string | null>(null);
  readonly lastUpdated = signal<Date | null>(null);
  /** Reloj compartido para los textos "hace X s". */
  readonly now = signal(Date.now());

  /** Solicitudes llegadas desde que se abrió el panel y aún no revisadas. */
  readonly newIds = signal<ReadonlySet<number>>(new Set());
  readonly notifications = signal<Reimbursement[]>([]);
  /** Última tanda de llegadas, para mostrar un aviso. */
  readonly arrivals = signal<{ items: Reimbursement[]; at: number } | null>(null);

  private poll?: ReturnType<typeof setInterval>;
  private clock?: ReturnType<typeof setInterval>;
  private readonly onVisible = () => {
    if (document.visibilityState === 'visible') this.refresh();
  };

  constructor() {
    inject(DestroyRef).onDestroy(() => this.stop());
  }

  /** Empieza a sincronizar (al entrar al panel con sesión). Llamarlo varias veces no duplica nada. */
  start(): void {
    if (this.poll) return;
    this.refresh(true);
    this.poll = setInterval(() => {
      if (document.visibilityState === 'visible') this.refresh();
    }, ReimbursementStore.refreshIntervalMs);
    this.clock = setInterval(() => this.now.set(Date.now()), 1000);
    document.addEventListener('visibilitychange', this.onVisible);
  }

  /** Detiene la sincronización y borra los datos (al cerrar sesión). */
  stop(): void {
    clearInterval(this.poll);
    clearInterval(this.clock);
    this.poll = this.clock = undefined;
    document.removeEventListener('visibilitychange', this.onVisible);
    this.inFlight?.unsubscribe();
    this.inFlight = undefined;
    this.knownIds = null;
    this.items.set([]);
    this.loading.set(true);
    this.error.set(null);
    this.lastUpdated.set(null);
    this.markAllSeen();
    this.arrivals.set(null);
  }

  /** `force` descarta una consulta en curso para reflejar de inmediato una decisión propia. */
  refresh(force = false): void {
    if (this.inFlight) {
      if (!force) return;
      this.inFlight.unsubscribe();
    }

    this.refreshing.set(true);
    const request = this.api
      .getAll()
      .pipe(
        finalize(() => {
          if (this.inFlight === request) this.inFlight = undefined;
          this.refreshing.set(false);
          this.loading.set(false);
        }),
      )
      .subscribe({
        next: (items) => this.apply(items),
        // Si falla una actualización se conservan los últimos datos y se reintenta en el siguiente ciclo.
        error: (err) => this.error.set(apiErrorMessage(err)),
      });
    this.inFlight = request;
  }

  approve(id: number): Observable<Reimbursement> {
    return this.api.approve(id).pipe(tap(() => this.markSeen(id)));
  }

  reject(id: number, reason: string): Observable<Reimbursement> {
    return this.api.reject(id, reason).pipe(tap(() => this.markSeen(id)));
  }

  markSeen(id: number): void {
    if (!this.newIds().has(id)) return;
    this.newIds.update((ids) => new Set([...ids].filter((x) => x !== id)));
    this.notifications.update((list) => list.filter((n) => n.id !== id));
  }

  markAllSeen(): void {
    this.newIds.set(new Set());
    this.notifications.set([]);
  }

  private apply(items: Reimbursement[]): void {
    if (this.knownIds) {
      const fresh = items.filter((item) => !this.knownIds!.has(item.id));
      if (fresh.length) {
        this.newIds.update((ids) => new Set([...ids, ...fresh.map((f) => f.id)]));
        this.notifications.update((list) => [...fresh, ...list].slice(0, 20));
        this.arrivals.set({ items: fresh, at: Date.now() });
      }
    }
    this.knownIds = new Set(items.map((item) => item.id));
    this.items.set(items);
    this.error.set(null);
    this.lastUpdated.set(new Date());
  }
}
