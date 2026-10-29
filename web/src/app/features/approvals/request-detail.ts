import { Component, computed, effect, input, output, signal, untracked } from '@angular/core';

import { AUTO_APPROVAL_LIMIT, Reimbursement, STATUS_LABELS } from '../../models/reimbursement.model';
import {
  avatarColor,
  categoryIcon,
  formatCop,
  formatDateTime,
  formatDuration,
  initials,
  requestCode,
  timeAgo,
} from '../../shared/format';

interface TimelineStep {
  icon: string;
  tone: 'neutral' | 'pending' | 'approved' | 'rejected';
  title: string;
  detail: string;
  when: string | null;
  current?: boolean;
}

/** Panel lateral con la ficha completa de una solicitud; también aloja el formulario de rechazo. */
@Component({
  selector: 'app-request-detail',
  templateUrl: './request-detail.html',
  styleUrl: './request-detail.scss',
})
export class RequestDetail {
  readonly item = input.required<Reimbursement>();
  readonly isNew = input(false);
  readonly now = input(Date.now());
  readonly submitting = input(false);
  readonly startInReject = input(false);
  readonly rejectError = input<string | null>(null);

  readonly closed = output<void>();
  readonly approve = output<void>();
  readonly reject = output<string>();

  protected readonly maxReasonLength = 500;
  protected readonly labels = STATUS_LABELS;
  protected readonly limit = AUTO_APPROVAL_LIMIT;

  protected readonly mode = signal<'detail' | 'reject'>('detail');
  protected readonly reason = signal('');
  protected readonly localError = signal<string | null>(null);

  protected readonly code = requestCode;
  protected readonly formatCop = formatCop;
  protected readonly formatDateTime = formatDateTime;
  protected readonly categoryIcon = categoryIcon;
  protected readonly initials = initials;
  protected readonly avatarColor = avatarColor;

  protected readonly isPending = computed(() => this.item().status === 'Pending');
  protected readonly error = computed(() => this.localError() ?? this.rejectError());

  protected readonly timeline = computed<TimelineStep[]>(() => {
    const item = this.item();
    const now = this.now();
    const manual = item.amount > AUTO_APPROVAL_LIMIT;
    const steps: TimelineStep[] = [
      {
        icon: 'add_circle',
        tone: 'neutral',
        title: 'Solicitud creada',
        detail: `Registrada por ${item.employeeName} desde la app móvil.`,
        when: formatDateTime(item.createdAtUtc),
      },
    ];

    if (!manual) {
      steps.push({
        icon: 'bolt',
        tone: 'approved',
        title: 'Aprobada automáticamente',
        detail: 'El monto está dentro del límite de $500.000 COP.',
        when: item.decidedAtUtc ? formatDateTime(item.decidedAtUtc) : null,
      });
      return steps;
    }

    steps.push({
      icon: 'groups',
      tone: 'neutral',
      title: 'Enviada al Equipo de Finanzas',
      detail: 'Supera $500.000 COP y requiere revisión manual.',
      when: formatDateTime(item.createdAtUtc),
    });

    const elapsed = (end: string | null) =>
      formatDuration((end ? new Date(end).getTime() : now) - new Date(item.createdAtUtc).getTime());

    if (item.status === 'Pending') {
      steps.push({
        icon: 'hourglass_top',
        tone: 'pending',
        title: 'Esperando decisión',
        detail: `En revisión ${timeAgo(item.createdAtUtc, now).replace('hace', 'desde hace')}.`,
        when: null,
        current: true,
      });
    } else {
      const approved = item.status === 'Approved';
      steps.push({
        icon: approved ? 'check_circle' : 'cancel',
        tone: approved ? 'approved' : 'rejected',
        title: approved ? 'Aprobada por el Equipo de Finanzas' : 'Rechazada por el Equipo de Finanzas',
        detail: approved
          ? `Tiempo de respuesta: ${elapsed(item.decidedAtUtc)}.`
          : `Motivo: ${item.rejectionReason}`,
        when: item.decidedAtUtc ? formatDateTime(item.decidedAtUtc) : null,
      });
    }
    return steps;
  });

  // Solo cambia al abrir otra solicitud: las actualizaciones automáticas traen el mismo id
  // y no deben borrar el motivo que el aprobador está escribiendo.
  private readonly itemId = computed(() => this.item().id);

  constructor() {
    effect(() => {
      this.itemId();
      untracked(() => {
        this.mode.set(this.startInReject() ? 'reject' : 'detail');
        this.reason.set('');
        this.localError.set(null);
      });
    });
  }

  protected onReasonInput(event: Event): void {
    this.reason.set((event.target as HTMLTextAreaElement).value);
    this.localError.set(null);
  }

  protected submitReject(): void {
    // La API también lo valida; aquí se evita una petición inútil.
    const reason = this.reason().trim();
    if (!reason) {
      this.localError.set('Escribe el motivo del rechazo.');
      return;
    }
    this.reject.emit(reason);
  }
}
