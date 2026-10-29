import { HttpErrorResponse, provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';

import { API_BASE_URL } from './api.config';
import { ReimbursementService, apiErrorMessage } from './services/reimbursement.service';
import { formatCop, formatDuration, requestCode, timeAgo } from './shared/format';

describe('format', () => {
  it('formatea montos en COP con separador de miles', () => {
    expect(formatCop(650000)).toBe('$ 650.000 COP');
    expect(formatCop(500000.01)).toBe('$ 500.000,01 COP');
  });

  it('expresa tiempos relativos y duraciones', () => {
    const now = Date.parse('2026-10-29T15:10:00Z');
    expect(timeAgo('2026-10-29T15:09:55Z', now)).toBe('hace 5 s');
    expect(timeAgo('2026-10-29T15:00:00Z', now)).toBe('hace 10 min');
    expect(formatDuration(3 * 3_600_000 + 20 * 60_000)).toBe('3 h 20 min');
  });

  it('genera el mismo código que la app móvil', () => {
    const item = { id: 7, createdAtUtc: '2026-10-29T15:00:00Z' } as Parameters<typeof requestCode>[0];
    expect(requestCode(item)).toBe('RB-2026-0007');
  });
});

describe('ReimbursementService', () => {
  let service: ReimbursementService;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    service = TestBed.inject(ReimbursementService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  it('filtra por estado con ?status=', () => {
    service.getAll('Pending').subscribe();
    const req = http.expectOne(`${API_BASE_URL}?status=Pending`);
    expect(req.request.method).toBe('GET');
    req.flush([]);
  });

  it('envía el motivo al rechazar', () => {
    service.reject(3, 'No cumple la política.').subscribe();
    const req = http.expectOne(`${API_BASE_URL}/3/reject`);
    expect(req.request.method).toBe('PATCH');
    expect(req.request.body).toEqual({ reason: 'No cumple la política.' });
    req.flush({});
  });
});

describe('apiErrorMessage', () => {
  it('usa el mensaje de la API', () => {
    const error = new HttpErrorResponse({ status: 409, error: { message: 'La solicitud 1 ya fue decidida.' } });
    expect(apiErrorMessage(error)).toBe('La solicitud 1 ya fue decidida.');
  });

  it('explica cuando la API está apagada', () => {
    expect(apiErrorMessage(new HttpErrorResponse({ status: 0 }))).toContain('No se pudo conectar');
  });
});
