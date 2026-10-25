import { useRouter, useRoute } from 'vue-router'
import { prefersReducedMotion } from '@/utils/motion'

export interface NavItem {
  label: string
  href: string
  isRoute: boolean
}

export const NAV_ITEMS: NavItem[] = [
  { label: 'Home', href: '/', isRoute: false },
  { label: 'Projects', href: '/#projects', isRoute: false },
  { label: 'Experience', href: '/#experience', isRoute: false },
  { label: 'About', href: '/#about', isRoute: false },
  { label: 'Contact', href: '/#contact', isRoute: false },
]

export const HEADER_HEIGHT = 80

// window.scrollTo ignores the CSS reduced-motion rule, so ask for an instant jump explicitly.
function scrollBehavior(): ScrollBehavior {
  return prefersReducedMotion() ? 'auto' : 'smooth'
}

/** Moves keyboard focus to a section the page just scrolled to, so the next Tab starts there. */
export function focusSection(el: HTMLElement): void {
  if (!el.hasAttribute('tabindex')) el.setAttribute('tabindex', '-1')
  el.focus({ preventScroll: true })
}

export function useScrollTo() {
  const router = useRouter()
  const route = useRoute()

  function scrollToHash(hash: string) {
    const el = document.querySelector<HTMLElement>(hash)
    if (el) {
      const top = el.getBoundingClientRect().top + window.scrollY - HEADER_HEIGHT
      window.scrollTo({ top, behavior: scrollBehavior() })
      focusSection(el)
    }
  }

  async function navigateTo(item: NavItem) {
    if (item.isRoute) {
      await router.push(item.href)
      return
    }

    const hash = item.href.includes('#') ? `#${item.href.split('#')[1]}` : ''

    if (item.href === '/') {
      if (route.path === '/') {
        window.scrollTo({ top: 0, behavior: scrollBehavior() })
      } else {
        await router.push('/')
      }
      return
    }

    if (route.path === '/') {
      scrollToHash(hash)
    } else {
      await router.push({ path: '/', hash })
    }
  }

  return { navigateTo, scrollToHash }
}
