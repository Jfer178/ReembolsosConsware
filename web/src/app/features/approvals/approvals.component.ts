import { HttpErrorResponse } from '@angular/common/http';
import { Component, computed, inject, signal } from '@angular/core';
import { finalize, forkJoin, of } from 'rxjs';

import {
  AUTO_APPROVAL_LIMIT,
  Reimbursement,
  ReimbursementStatus,
  STATUS_LABELS,
} from '../../models/reimbursement.model';
import { ReimbursementService, apiErrorMessage } from '../../services/reimbursement.service';
import {
  avatarColor,
  categoryIcon,
  formatCop,
  formatCopNumber,
  formatDate,
  initials,
  requestCode,
} from '../../shared/format';

type Tab = ReimbursementStatus | 'All';

interface Toast {
  kind: 'success' | 'warning' | 'error';
  text: string;
}

@Component({
  selector: 'app-approvals',
  templateUrl: './approvals.component.html',
  styleUrl: './approvals.component.scss',
  host: { '(document:keydown.escape)': 'closeDialogs()' },
})
export class Approvals {
  private readonly service = inject(ReimbursementService);
  private requestId = 0;
  private toastTimer?: ReturnType<typeof setTimeout>;

  protected readonly tabs: { value: Tab; label: string }[] = [
    { value: 'Pending', label: 'Pendientes' },
    { value: 'Approved', label: 'Aprobadas' },
    { value: 'Rejected', label: 'Rechazadas' },
    { value: 'All', label: 'Todas' },
  ];
  protected readonly labels = STATUS_LABELS;
  protected readonly limit = AUTO_APPROVAL_LIMIT;
  protected readonly maxReasonLength = 500;
  protected readonly skeletonRows = [1, 2, 3, 4];

  protected readonly code = requestCode;
  protected readonly formatCop = formatCop;
  protected readonly formatCopNumber = formatCopNumber;
  protected readonly formatDate = formatDate;
  protected readonly categoryIcon = categoryIcon;
  protected readonly initials = initials;
  protected readonly avatarColor = avatarColor;

  protected readonly tab = signal<Tab>('Pending');
  protected readonly all = signal<Reimbursement[]>([]);
  protected readonly rows = signal<Reimbursement[]>([]);
  protected readonly search = signal('');
  protected readonly loading = signal(true);
  protected readonly error = signal<string | null>(null);

  protected readonly approving = signal<Reimbursement | null>(null);
  protected readonly rejecting = signal<Reimbursement | null>(null);
  protected readonly reason = signal('');
  protected readonly reasonError = signal<string | null>(null);
  protected readonly submitting = signal(false);
  protected readonly toast = signal<Toast | null>(null);

  protected readonly counts = computed(() => {
    const items = this.all();
    const count = (status: ReimbursementStatus) => items.filter((i) => i.status === status).length;
    return {
      Pending: count('Pending'),
      Approved: count('Approved'),
      Rejected: count('Rejected'),
      All: items.length,
    } satisfies Record<Tab, number>;
  });

  protected readonly approvedTotal = computed(() =>
    this.all()
      .filter((i) => i.status === 'Approved')
      .reduce((sum, i) => sum + i.amount, 0),
  );

  protected readonly visibleRows = computed(() => {
    const query = this.search().trim().toLowerCase();
    if (!query) return this.rows();
    return this.rows().filter((item) =>
      [item.employeeName, item.category, item.description, requestCode(item)].some((value) =>
        value.toLowerCase().includes(query),
      ),
    );
  });

  protected readonly emptyState = computed(() => {
    if (this.search().trim()) {
      return { title: 'Sin resultados', text: 'Ninguna solicitud coincide con la búsqueda.' };
    }
    return this.tab() === 'Pending'
      ? { title: '¡Todo al día!', text: 'No hay solicitudes pendientes por revisar.' }
      : { title: 'Sin solicitudes', text: 'No hay solicitudes en este estado.' };
  });

  constructor() {
    this.load();
  }

  /** La tabla usa el filtro por estado de la API; las tarjetas y contadores, la lista completa. */
  protected load(): void {
    const request = ++this.requestId;
    const tab = this.tab();
    this.loading.set(true);
    this.error.set(null);

    forkJoin({
      all: this.service.getAll(),
      rows: tab === 'All' ? of(null) : this.service.getAll(tab),
    }).subscribe({
      next: ({ all, rows }) => {
        if (request !== this.requestId) return; // respuesta de una pestaña anterior
        this.all.set(all);
        this.rows.set(rows ?? all);
        this.loading.set(false);
      },
      error: (err) => {
        if (request !== this.requestId) return;
        this.error.set(apiErrorMessage(err));
        this.loading.set(false);
      },
    });
  }

  protected selectTab(tab: Tab): void {
    if (tab === this.tab()) return;
    this.tab.set(tab);
    this.rows.set([]);
    this.load();
  }

  protected onSearch(event: Event): void {
    this.search.set((event.target as HTMLInputElement).value);
  }

  protected openReject(item: Reimbursement): void {
    this.reason.set('');
    this.reasonError.set(null);
    this.rejecting.set(item);
  }

  protected onReasonInput(event: Event): void {
    this.reason.set((event.target as HTMLTextAreaElement).value);
    if (this.reasonError()) this.reasonError.set(null);
  }

  protected closeDialogs(): void {
    if (this.submitting()) return;
    this.approving.set(null);
    this.rejecting.set(null);
  }

  protected confirmApprove(): void {
    const item = this.approving();
    if (!item || this.submitting()) return;

    this.submitting.set(true);
    this.service
      .approve(item.id)
      .pipe(finalize(() => this.submitting.set(false)))
      .subscribe({
        next: () => {
          this.approving.set(null);
          this.showToast('success', `Solicitud ${requestCode(item)} aprobada.`);
          this.load();
        },
        error: (err) => {
          this.approving.set(null);
          this.handleDecisionError(err);
        },
      });
  }

  protected confirmReject(): void {
    const item = this.rejecting();
    if (!item || this.submitting()) return;

    // La API también lo valida; aquí se evita una petición inútil.
    const reason = this.reason().trim();
    if (!reason) {
      this.reasonError.set('Escribe el motivo del rechazo.');
      return;
    }

    this.submitting.set(true);
    this.service
      .reject(item.id, reason)
      .pipe(finalize(() => this.submitting.set(false)))
      .subscribe({
        next: () => {
          this.rejecting.set(null);
          this.showToast('success', `Solicitud ${requestCode(item)} rechazada.`);
          this.load();
        },
        error: (err) => {
          if (err instanceof HttpErrorResponse && err.status === 400) {
            this.reasonError.set(apiErrorMessage(err));
            return;
          }
          this.rejecting.set(null);
          this.handleDecisionError(err);
        },
      });
  }

  private handleDecisionError(err: unknown): void {
    // 409: otra persona ya la decidió; 404: ya no existe. En ambos casos se recarga la tabla.
    if (err instanceof HttpErrorResponse && (err.status === 409 || err.status === 404)) {
      this.showToast('warning', `${apiErrorMessage(err)} La lista se actualizó.`);
      this.load();
      return;
    }
    this.showToast('error', apiErrorMessage(err));
  }

  private showToast(kind: Toast['kind'], text: string): void {
    clearTimeout(this.toastTimer);
    this.toast.set({ kind, text });
    this.toastTimer = setTimeout(() => this.toast.set(null), 4500);
  }
}
