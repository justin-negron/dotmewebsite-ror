import { useRouter, useRoute } from 'vue-router'

export interface NavItem {
  label: string
  href: string
  isRoute: boolean
}

export const NAV_ITEMS: NavItem[] = [
  { label: 'Home', href: '/', isRoute: false },
  { label: 'Projects', href: '/#projects', isRoute: false },
  { label: 'Experience', href: '/#experience', isRoute: false },
  { label: 'Blog', href: '/blog', isRoute: true },
  { label: 'Contact', href: '/#contact', isRoute: false },
]

export const HEADER_HEIGHT = 80

export function useScrollTo() {
  const router = useRouter()
  const route = useRoute()

  function scrollToHash(hash: string) {
    const el = document.querySelector(hash)
    if (el) {
      const top = el.getBoundingClientRect().top + window.scrollY - HEADER_HEIGHT
      window.scrollTo({ top, behavior: 'smooth' })
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
        window.scrollTo({ top: 0, behavior: 'smooth' })
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
