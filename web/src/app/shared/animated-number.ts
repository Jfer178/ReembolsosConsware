import { Component, computed, effect, input, signal, untracked } from '@angular/core';

const reducedMotion = () => window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ?? false;

/**
 * Número que cuenta desde su valor anterior hasta el nuevo (también cuando la lista se actualiza en vivo).
 * Durante la animación muestra enteros; al terminar, el valor exacto.
 */
@Component({
  selector: 'app-animated-number',
  template: '{{ text() }}',
})
export class AnimatedNumber {
  readonly value = input.required<number>();
  readonly format = input<(value: number) => string>((value) => Math.round(value).toString());
  readonly duration = input(900);

  private readonly display = signal(0);
  protected readonly text = computed(() => this.format()(this.display()));

  constructor() {
    effect((onCleanup) => {
      const target = this.value();
      const start = untracked(() => this.display());
      if (start === target || reducedMotion()) {
        this.display.set(target);
        return;
      }

      const begin = performance.now();
      const duration = untracked(() => this.duration());
      let frame = 0;
      const step = (now: number) => {
        const progress = Math.min(1, (now - begin) / duration);
        const eased = 1 - Math.pow(1 - progress, 3);
        this.display.set(progress === 1 ? target : Math.round(start + (target - start) * eased));
        if (progress < 1) frame = requestAnimationFrame(step);
      };
      frame = requestAnimationFrame(step);
      onCleanup(() => cancelAnimationFrame(frame));
    });
  }
}
