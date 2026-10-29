import { HttpErrorResponse } from '@angular/common/http';
import { Component, computed, effect, inject, signal, untracked } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { ActivatedRoute, Router } from '@angular/router';
import { catchError, concatMap, finalize, from, map, of, toArray } from 'rxjs';

import {
  AUTO_APPROVAL_LIMIT,
  Reimbursement,
  ReimbursementStatus,
  STATUS_LABELS,
} from '../../models/reimbursement.model';
import { ReimbursementStore } from '../../services/reimbursement-store';
import { apiErrorMessage } from '../../services/reimbursement.service';
import {
  avatarColor,
  categoryIcon,
  formatCop,
  formatCopNumber,
  formatDate,
  initials,
  requestCode,
  timeAgo,
} from '../../shared/format';
import { AnimatedNumber } from '../../shared/animated-number';
import { Topbar } from '../../shared/topbar';
import { RequestDetail } from './request-detail';

type Tab = ReimbursementStatus | 'All';
type AmountRange = 'all' | 'auto' | 'manual';
type SortOrder = 'newest' | 'oldest' | 'highest' | 'lowest';

interface Toast {
  kind: 'success' | 'warning' | 'error' | 'info';
  text: string;
}

@Component({
  selector: 'app-approvals',
  imports: [Topbar, RequestDetail, AnimatedNumber],
  templateUrl: './approvals.component.html',
  styleUrl: './approvals.component.scss',
  host: { '(document:keydown.escape)': 'onEscape()' },
})
export class Approvals {
  protected readonly store = inject(ReimbursementStore);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly createdAt = Date.now();
  private toastTimer?: ReturnType<typeof setTimeout>;

  protected readonly pageSize = 8;
  protected readonly limit = AUTO_APPROVAL_LIMIT;
  protected readonly labels = STATUS_LABELS;
  protected readonly skeletonRows = [1, 2, 3, 4, 5];
  protected readonly tabs: { value: Tab; label: string }[] = [
    { value: 'Pending', label: 'Pendientes' },
    { value: 'Approved', label: 'Aprobadas' },
    { value: 'Rejected', label: 'Rechazadas' },
    { value: 'All', label: 'Todas' },
  ];
  protected readonly amountRanges: { value: AmountRange; label: string }[] = [
    { value: 'all', label: 'Todos los montos' },
    { value: 'auto', label: 'Hasta $500.000' },
    { value: 'manual', label: 'Más de $500.000' },
  ];
  protected readonly sortOrders: { value: SortOrder; label: string }[] = [
    { value: 'newest', label: 'Más recientes' },
    { value: 'oldest', label: 'Más antiguas' },
    { value: 'highest', label: 'Mayor monto' },
    { value: 'lowest', label: 'Menor monto' },
  ];

  protected readonly code = requestCode;
  protected readonly formatCop = formatCop;
  protected readonly formatCopNumber = formatCopNumber;
  protected readonly formatDate = formatDate;
  protected readonly categoryIcon = categoryIcon;
  protected readonly initials = initials;
  protected readonly avatarColor = avatarColor;
  protected readonly timeAgo = timeAgo;

  // ---------- Filtros y tabla ----------
  protected readonly tab = signal<Tab>('Pending');
  protected readonly search = signal('');
  protected readonly category = signal('');
  protected readonly amountRange = signal<AmountRange>('all');
  protected readonly sort = signal<SortOrder>('newest');
  protected readonly filtersOpen = signal(false);
  protected readonly page = signal(1);
  protected readonly selection = signal<ReadonlySet<number>>(new Set());

  // ---------- Diálogos ----------
  protected readonly confirming = signal<Reimbursement[] | null>(null);
  protected readonly startInReject = signal(false);
  protected readonly rejectError = signal<string | null>(null);
  protected readonly submitting = signal(false);
  protected readonly toast = signal<Toast | null>(null);

  /** La solicitud abierta vive en la URL (?solicitud=ID), así se puede enlazar o abrir desde la campana. */
  private readonly selectedId = toSignal(
    this.route.queryParamMap.pipe(map((params) => Number(params.get('solicitud')) || null)),
    { initialValue: null },
  );

  protected readonly detailItem = computed(() => {
    const id = this.selectedId();
    return id ? (this.store.items().find((item) => item.id === id) ?? null) : null;
  });

  protected readonly counts = computed(() => {
    const items = this.store.items();
    const count = (status: ReimbursementStatus) => items.filter((i) => i.status === status).length;
    return {
      Pending: count('Pending'),
      Approved: count('Approved'),
      Rejected: count('Rejected'),
      All: items.length,
    } satisfies Record<Tab, number>;
  });

  protected readonly approvedTotal = computed(() =>
    this.store
      .items()
      .filter((i) => i.status === 'Approved')
      .reduce((sum, i) => sum + i.amount, 0),
  );

  protected readonly pendingTotal = computed(() =>
    this.store
      .items()
      .filter((i) => i.status === 'Pending')
      .reduce((sum, i) => sum + i.amount, 0),
  );

  protected readonly categories = computed(() =>
    [...new Set(this.store.items().map((i) => i.category))].sort((a, b) => a.localeCompare(b, 'es')),
  );

  protected readonly activeFilters = computed(
    () => (this.category() ? 1 : 0) + (this.amountRange() !== 'all' ? 1 : 0) + (this.sort() !== 'newest' ? 1 : 0),
  );

  protected readonly filtered = computed(() => {
    const tab = this.tab();
    const category = this.category();
    const range = this.amountRange();
    const query = this.search().trim().toLowerCase();

    const list = this.store.items().filter((item) => {
      if (tab !== 'All' && item.status !== tab) return false;
      if (category && item.category !== category) return false;
      if (range === 'auto' && item.amount > AUTO_APPROVAL_LIMIT) return false;
      if (range === 'manual' && item.amount <= AUTO_APPROVAL_LIMIT) return false;
      if (!query) return true;
      return [item.employeeName, item.category, item.description, requestCode(item)].some((value) =>
        value.toLowerCase().includes(query),
      );
    });

    const byDate = (a: Reimbursement, b: Reimbursement) => a.createdAtUtc.localeCompare(b.createdAtUtc) || a.id - b.id;
    return list.sort(
      {
        newest: (a: Reimbursement, b: Reimbursement) => byDate(b, a),
        oldest: byDate,
        highest: (a: Reimbursement, b: Reimbursement) => b.amount - a.amount,
        lowest: (a: Reimbursement, b: Reimbursement) => a.amount - b.amount,
      }[this.sort()],
    );
  });

  protected readonly pageCount = computed(() => Math.max(1, Math.ceil(this.filtered().length / this.pageSize)));
  protected readonly currentPage = computed(() => Math.min(this.page(), this.pageCount()));
  protected readonly pageRows = computed(() => {
    const start = (this.currentPage() - 1) * this.pageSize;
    return this.filtered().slice(start, start + this.pageSize);
  });
  protected readonly pageNumbers = computed(() => Array.from({ length: this.pageCount() }, (_, i) => i + 1));
  protected readonly rangeLabel = computed(() => {
    const total = this.filtered().length;
    if (!total) return 'Sin resultados';
    const start = (this.currentPage() - 1) * this.pageSize + 1;
    return `Mostrando ${start}–${Math.min(start + this.pageSize - 1, total)} de ${total}`;
  });

  /** Solo las pendientes se pueden seleccionar; si alguien decide una, sale de la selección. */
  protected readonly selectedItems = computed(() =>
    this.store.items().filter((i) => i.status === 'Pending' && this.selection().has(i.id)),
  );
  protected readonly selectedTotal = computed(() => this.selectedItems().reduce((sum, i) => sum + i.amount, 0));
  protected readonly selectablePageRows = computed(() => this.pageRows().filter((i) => i.status === 'Pending'));
  protected readonly allPageSelected = computed(() => {
    const rows = this.selectablePageRows();
    return rows.length > 0 && rows.every((i) => this.selection().has(i.id));
  });

  protected readonly liveLabel = computed(() => {
    if (this.store.error()) return 'Sin conexión · reintentando';
    const updated = this.store.lastUpdated();
    return updated ? `En vivo · actualizado ${timeAgo(updated, this.store.now())}` : 'Conectando...';
  });

  protected readonly emptyState = computed(() => {
    if (this.search().trim() || this.activeFilters()) {
      return { title: 'Sin resultados', text: 'Ninguna solicitud coincide con la búsqueda o los filtros.' };
    }
    return this.tab() === 'Pending'
      ? { title: '¡Todo al día!', text: 'No hay solicitudes pendientes por revisar.' }
      : { title: 'Sin solicitudes', text: 'No hay solicitudes en este estado.' };
  });

  constructor() {
    // Abrir el detalle cuenta como revisar la solicitud nueva.
    effect(() => {
      const item = this.detailItem();
      if (item) untracked(() => this.store.markSeen(item.id));
    });

    // Aviso cuando la actualización automática trae solicitudes nuevas.
    effect(() => {
      const arrival = this.store.arrivals();
      if (!arrival || arrival.at < this.createdAt) return;
      untracked(() => {
        const [first] = arrival.items;
        this.showToast(
          'info',
          arrival.items.length === 1
            ? `Nueva solicitud ${requestCode(first)} de ${first.employeeName} por ${formatCop(first.amount)}.`
            : `Llegaron ${arrival.items.length} solicitudes nuevas.`,
        );
      });
    });
  }

  // ---------- Filtros ----------
  protected selectTab(tab: Tab): void {
    this.tab.set(tab);
    this.page.set(1);
  }

  protected onSearch(event: Event): void {
    this.search.set((event.target as HTMLInputElement).value);
    this.page.set(1);
  }

  protected setCategory(event: Event): void {
    this.category.set((event.target as HTMLSelectElement).value);
    this.page.set(1);
  }

  protected setAmountRange(range: AmountRange): void {
    this.amountRange.set(range);
    this.page.set(1);
  }

  protected setSort(event: Event): void {
    this.sort.set((event.target as HTMLSelectElement).value as SortOrder);
  }

  protected clearFilters(): void {
    this.category.set('');
    this.amountRange.set('all');
    this.sort.set('newest');
    this.page.set(1);
  }

  // ---------- Selección ----------
  protected toggleSelected(item: Reimbursement): void {
    this.selection.update((ids) => {
      const next = new Set(ids);
      if (!next.delete(item.id)) next.add(item.id);
      return next;
    });
  }

  protected toggleAllOnPage(): void {
    const rows = this.selectablePageRows();
    const select = !this.allPageSelected();
    this.selection.update((ids) => {
      const next = new Set(ids);
      rows.forEach((row) => (select ? next.add(row.id) : next.delete(row.id)));
      return next;
    });
  }

  protected clearSelection(): void {
    this.selection.set(new Set());
  }

  // ---------- Detalle ----------
  protected openDetail(item: Reimbursement, reject = false): void {
    this.startInReject.set(reject);
    this.rejectError.set(null);
    this.router.navigate([], { queryParams: { solicitud: item.id }, queryParamsHandling: 'merge' });
  }

  protected closeDetail(): void {
    if (this.submitting()) return;
    this.router.navigate([], { queryParams: { solicitud: null }, queryParamsHandling: 'merge' });
  }

  protected onEscape(): void {
    if (this.submitting()) return;
    if (this.confirming()) this.confirming.set(null);
    else if (this.filtersOpen()) this.filtersOpen.set(false);
    else if (this.detailItem()) this.closeDetail();
  }

  // ---------- Decisiones ----------
  protected askApprove(items: Reimbursement[]): void {
    if (items.length) this.confirming.set(items);
  }

  protected confirmApprove(): void {
    const items = this.confirming();
    if (!items?.length || this.submitting()) return;

    this.submitting.set(true);
    // Una petición por solicitud, en orden; si una falla (p. ej. 409) las demás continúan.
    from(items)
      .pipe(
        concatMap((item) =>
          this.store.approve(item.id).pipe(
            map(() => ({ item, error: null as unknown })),
            catchError((error: unknown) => of({ item, error })),
          ),
        ),
        toArray(),
        finalize(() => this.submitting.set(false)),
      )
      .subscribe((results) => {
        this.submitting.set(false); // antes de closeDetail, que se bloquea mientras se envía
        this.confirming.set(null);
        this.clearSelection();
        const failed = results.filter((r) => r.error);
        const approved = results.length - failed.length;

        if (results.length === 1) {
          if (failed.length) {
            this.handleDecisionError(failed[0].error);
            return;
          }
          this.showToast('success', `Solicitud ${requestCode(items[0])} aprobada.`);
          this.closeDetail();
        } else {
          this.showToast(
            failed.length ? 'warning' : 'success',
            `${approved} ${approved === 1 ? 'solicitud aprobada' : 'solicitudes aprobadas'}` +
              (failed.length ? `; ${failed.length} no se pudieron aprobar porque ya estaban decididas.` : '.'),
          );
        }
        this.store.refresh(true);
      });
  }

  protected rejectItem(item: Reimbursement, reason: string): void {
    if (this.submitting()) return;
    this.submitting.set(true);
    this.rejectError.set(null);
    this.store
      .reject(item.id, reason)
      .pipe(finalize(() => this.submitting.set(false)))
      .subscribe({
        next: () => {
          this.showToast('success', `Solicitud ${requestCode(item)} rechazada.`);
          this.submitting.set(false);
          this.closeDetail();
          this.store.refresh(true);
        },
        error: (err) => {
          if (err instanceof HttpErrorResponse && err.status === 400) {
            this.rejectError.set(apiErrorMessage(err));
            return;
          }
          this.handleDecisionError(err);
        },
      });
  }

  private handleDecisionError(err: unknown): void {
    // 409: otra persona ya la decidió; 404: ya no existe. En ambos casos se sincroniza la lista.
    if (err instanceof HttpErrorResponse && (err.status === 409 || err.status === 404)) {
      this.showToast('warning', `${apiErrorMessage(err)} La lista se actualizó.`);
      this.store.refresh(true);
      return;
    }
    this.showToast('error', apiErrorMessage(err));
  }

  private showToast(kind: Toast['kind'], text: string): void {
    clearTimeout(this.toastTimer);
    this.toast.set({ kind, text });
    this.toastTimer = setTimeout(() => this.toast.set(null), 5000);
  }
}
