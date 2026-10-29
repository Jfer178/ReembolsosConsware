import { Reimbursement } from '../models/reimbursement.model';

const MONTHS = ['ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.', 'jul.', 'ago.', 'sep.', 'oct.', 'nov.', 'dic.'];

const CATEGORY_ICONS: Record<string, string> = {
  transporte: 'directions_car',
  alimentación: 'restaurant',
  hospedaje: 'hotel',
  tiquetes: 'flight',
  papelería: 'description',
};

const AVATAR_COLORS = ['#1668F2', '#7B5CF0', '#0EA5A4', '#E67E00', '#DB2777', '#1A2B6D'];

/** 650000 -> "$ 650.000"; 500000.01 -> "$ 500.000,01" */
export function formatCopNumber(amount: number): string {
  const whole = Math.trunc(amount);
  const cents = Math.round((amount - whole) * 100);
  const grouped = whole.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.');
  return `$ ${grouped}${cents ? ',' + cents.toString().padStart(2, '0') : ''}`;
}

export function formatCop(amount: number): string {
  return `${formatCopNumber(amount)} COP`;
}

/** Fecha en hora local: "14 ene. 2026" */
export function formatDate(isoUtc: string): string {
  const date = new Date(isoUtc);
  return `${date.getDate()} ${MONTHS[date.getMonth()]} ${date.getFullYear()}`;
}

/** Código legible, igual al de la app móvil: RB-2026-0007 */
export function requestCode(item: Reimbursement): string {
  return `RB-${new Date(item.createdAtUtc).getFullYear()}-${item.id.toString().padStart(4, '0')}`;
}

export function categoryIcon(category: string): string {
  return CATEGORY_ICONS[category.trim().toLowerCase()] ?? 'receipt_long';
}

export function initials(name: string): string {
  return name
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0].toUpperCase())
    .join('');
}

/** Color estable por nombre para el avatar del empleado. */
export function avatarColor(name: string): string {
  const hash = [...name].reduce((acc, char) => acc + char.charCodeAt(0), 0);
  return AVATAR_COLORS[hash % AVATAR_COLORS.length];
}
