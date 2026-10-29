import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, throwError } from 'rxjs';

import { API_ROOT, LOGIN_URL } from '../api.config';
import { AuthService } from './auth.service';

/** Agrega el token a las llamadas a la API y, si la API responde 401, vuelve al login. */
export const authInterceptor: HttpInterceptorFn = (request, next) => {
  const auth = inject(AuthService);
  const token = auth.token();
  const isApi = request.url.startsWith(API_ROOT);
  const isLogin = request.url === LOGIN_URL;

  const authorized =
    isApi && !isLogin && token ? request.clone({ setHeaders: { Authorization: `Bearer ${token}` } }) : request;

  return next(authorized).pipe(
    catchError((error: unknown) => {
      if (error instanceof HttpErrorResponse && error.status === 401 && isApi && !isLogin && auth.isLoggedIn()) {
        auth.logout(true);
      }
      return throwError(() => error);
    }),
  );
};
