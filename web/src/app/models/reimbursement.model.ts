export type ReimbursementStatus = 'Pending' | 'Approved' | 'Rejected';

export interface Reimbursement {
  id: number;
  employeeName: string;
  amount: number;
  category: string;
  description: string;
  status: ReimbursementStatus;
  rejectionReason: string | null;
  createdAtUtc: string;
  decidedAtUtc: string | null;
}

/** Misma política que el backend; en la UI solo se usa para mostrar avisos. */
export const AUTO_APPROVAL_LIMIT = 500_000;

export const STATUS_LABELS: Record<ReimbursementStatus, { singular: string; plural: string; icon: string }> = {
  Pending: { singular: 'Pendiente', plural: 'Pendientes', icon: 'schedule' },
  Approved: { singular: 'Aprobada', plural: 'Aprobadas', icon: 'check_circle' },
  Rejected: { singular: 'Rechazada', plural: 'Rechazadas', icon: 'cancel' },
};
