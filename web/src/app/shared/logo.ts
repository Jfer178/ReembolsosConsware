import { Component, input } from '@angular/core';

/** Símbolo de Consware en SVG (mismo trazo que en la app móvil). */
@Component({
  selector: 'app-logo-mark',
  template: `
    <svg viewBox="0 0 156 100" [attr.width]="size() * 1.56" [attr.height]="size()" aria-hidden="true">
      <g [attr.stroke]="color()" stroke-width="22" stroke-linecap="round" stroke-linejoin="round" fill="none">
        <path d="M14 40 L42 84 L90 30" />
        <path d="M90 86 L140 28" />
      </g>
      <circle cx="52" cy="11" r="10" [attr.fill]="color()" />
    </svg>
  `,
  styles: ':host { display: inline-flex; }',
})
export class LogoMark {
  readonly size = input(32);
  readonly color = input('#1A2B6D');
}
