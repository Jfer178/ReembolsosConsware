import { Component, computed, inject } from '@angular/core';
import { RouterLink } from '@angular/router';

import { AUTO_APPROVAL_LIMIT, ReimbursementStatus, STATUS_LABELS } from '../../models/reimbursement.model';
import { ReimbursementStore } from '../../services/reimbursement-store';
import {
  avatarColor,
  categoryIcon,
  formatCop,
  formatCopNumber,
  formatDuration,
  initials,
  requestCode,
  timeAgo,
} from '../../shared/format';
import { Topbar } from '../../shared/topbar';

const STATUS_COLORS: Record<ReimbursementStatus, string> = {
  Pending: '#e67e00',
  Approved: '#1e9e55',
  Rejected: '#e2324f',
};

/** Indicadores calculados en el cliente a partir de las mismas solicitudes que muestra el panel. */
@Component({
  selector: 'app-reports',
  imports: [Topbar, RouterLink],
  templateUrl: './reports.component.html',
  styleUrl: './reports.component.scss',
})
export class Reports {
  protected readonly store = inject(ReimbursementStore);

  protected readonly labels = STATUS_LABELS;
  protected readonly statusColors = STATUS_COLORS;
  protected readonly code = requestCode;
  protected readonly formatCop = formatCop;
  protected readonly formatCopNumber = formatCopNumber;
  protected readonly categoryIcon = categoryIcon;
  protected readonly initials = initials;
  protected readonly avatarColor = avatarColor;
  protected readonly timeAgo = timeAgo;

  private readonly items = this.store.items;

  protected readonly totalRequested = computed(() => this.items().reduce((sum, i) => sum + i.amount, 0));

  protected readonly autoApprovalRate = computed(() => {
    const items = this.items();
    if (!items.length) return 0;
    return Math.round((items.filter((i) => i.amount <= AUTO_APPROVAL_LIMIT).length / items.length) * 100);
  });

  /** Promedio entre creación y decisión de las solicitudes que revisó el equipo (> $500.000). */
  protected readonly averageReviewTime = computed(() => {
    const reviewed = this.items().filter((i) => i.amount > AUTO_APPROVAL_LIMIT && i.decidedAtUtc);
    if (!reviewed.length) return null;
    const total = reviewed.reduce(
      (sum, i) => sum + (new Date(i.decidedAtUtc!).getTime() - new Date(i.createdAtUtc).getTime()),
      0,
    );
    return { label: formatDuration(total / reviewed.length), count: reviewed.length };
  });

  protected readonly byStatus = computed(() => {
    const items = this.items();
    const total = items.length || 1;
    return (Object.keys(STATUS_COLORS) as ReimbursementStatus[]).map((status) => {
      const count = items.filter((i) => i.status === status).length;
      return { status, count, percent: Math.round((count / total) * 100) };
    });
  });

  /** Gráfico de dona con conic-gradient, sin librerías de gráficos. */
  protected readonly donut = computed(() => {
    const items = this.items();
    if (!items.length) return 'conic-gradient(#eef3fb 0 100%)';
    let start = 0;
    const segments = this.byStatus().map(({ status, count }) => {
      const end = start + (count / items.length) * 100;
      const segment = `${STATUS_COLORS[status]} ${start}% ${end}%`;
      start = end;
      return segment;
    });
    return `conic-gradient(${segments.join(', ')})`;
  });

  protected readonly byCategory = computed(() => {
    const groups = new Map<string, { amount: number; count: number }>();
    for (const item of this.items()) {
      const group = groups.get(item.category) ?? { amount: 0, count: 0 };
      group.amount += item.amount;
      group.count += 1;
      groups.set(item.category, group);
    }
    const rows = [...groups.entries()]
      .map(([category, g]) => ({ category, ...g }))
      .sort((a, b) => b.amount - a.amount);
    const max = rows[0]?.amount || 1;
    return rows.map((row) => ({ ...row, width: Math.max(4, Math.round((row.amount / max) * 100)) }));
  });

  protected readonly byEmployee = computed(() => {
    const groups = new Map<string, { total: number; count: number } & Record<ReimbursementStatus, number>>();
    for (const item of this.items()) {
      const group = groups.get(item.employeeName) ?? { total: 0, count: 0, Pending: 0, Approved: 0, Rejected: 0 };
      group.total += item.amount;
      group.count += 1;
      group[item.status] += 1;
      groups.set(item.employeeName, group);
    }
    return [...groups.entries()].map(([name, g]) => ({ name, ...g })).sort((a, b) => b.total - a.total);
  });

  protected readonly recentDecisions = computed(() =>
    this.items()
      .filter((i) => i.decidedAtUtc)
      .sort((a, b) => b.decidedAtUtc!.localeCompare(a.decidedAtUtc!))
      .slice(0, 6),
  );
}
