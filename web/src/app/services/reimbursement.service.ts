import { HttpClient, HttpErrorResponse, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { API_BASE_URL } from '../api.config';
import { Reimbursement, ReimbursementStatus } from '../models/reimbursement.model';

@Injectable({ providedIn: 'root' })
export class ReimbursementService {
  private readonly http = inject(HttpClient);

  getAll(status?: ReimbursementStatus): Observable<Reimbursement[]> {
    const params = status ? new HttpParams().set('status', status) : undefined;
    return this.http.get<Reimbursement[]>(API_BASE_URL, { params });
  }

  approve(id: number): Observable<Reimbursement> {
    return this.http.patch<Reimbursement>(`${API_BASE_URL}/${id}/approve`, {});
  }

  reject(id: number, reason: string): Observable<Reimbursement> {
    return this.http.patch<Reimbursement>(`${API_BASE_URL}/${id}/reject`, { reason });
  }
}

/** Traduce cualquier error HTTP a un mensaje que se puede mostrar al aprobador. */
export function apiErrorMessage(error: unknown): string {
  if (!(error instanceof HttpErrorResponse)) return 'Ocurrió un error inesperado.';
  if (error.status === 0) {
    return 'No se pudo conectar con el servidor. Verifica que la API esté encendida.';
  }

  // La API responde los errores como {"message": "..."}.
  const message = (error.error as { message?: unknown } | null)?.message;
  if (typeof message === 'string' && message.trim()) return message;

  switch (error.status) {
    case 400:
      return 'Los datos enviados no son válidos.';
    case 404:
      return 'No se encontró la solicitud.';
    case 409:
      return 'La solicitud ya fue decidida.';
    default:
      return error.status >= 500
        ? 'El servidor tuvo un problema. Intenta más tarde.'
        : `Error inesperado del servidor (código ${error.status}).`;
  }
}
