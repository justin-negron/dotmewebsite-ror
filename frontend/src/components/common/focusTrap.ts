const FOCUSABLE = 'a[href], button:not([disabled])'

export function trapTab(container: HTMLElement | null, e: KeyboardEvent): void {
  const focusable = Array.from(container?.querySelectorAll<HTMLElement>(FOCUSABLE) ?? [])
  const first = focusable[0]
  const last = focusable[focusable.length - 1]
  if (!first || !last) return

  if (e.shiftKey && document.activeElement === first) {
    e.preventDefault()
    last.focus()
  } else if (!e.shiftKey && document.activeElement === last) {
    e.preventDefault()
    first.focus()
  }
}
