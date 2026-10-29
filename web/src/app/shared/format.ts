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

/** Fecha y hora local: "14 ene. 2026, 09:41" */
export function formatDateTime(isoUtc: string): string {
  const date = new Date(isoUtc);
  const time = `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
  return `${formatDate(isoUtc)}, ${time}`;
}

/** Tiempo relativo: "hace 5 s", "hace 3 min", "hace 2 h", "hace 4 días" */
export function timeAgo(from: Date | string, now: number = Date.now()): string {
  const seconds = Math.max(0, Math.round((now - new Date(from).getTime()) / 1000));
  if (seconds < 60) return `hace ${seconds} s`;
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `hace ${minutes} min`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `hace ${hours} h`;
  const days = Math.floor(hours / 24);
  return `hace ${days} ${days === 1 ? 'día' : 'días'}`;
}

/** Duración legible: "45 s", "12 min", "3 h 20 min", "2 días" */
export function formatDuration(ms: number): string {
  const minutes = Math.round(ms / 60000);
  if (minutes < 1) return `${Math.round(ms / 1000)} s`;
  if (minutes < 60) return `${minutes} min`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return minutes % 60 ? `${hours} h ${minutes % 60} min` : `${hours} h`;
  const days = Math.round(hours / 24);
  return `${days} ${days === 1 ? 'día' : 'días'}`;
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
