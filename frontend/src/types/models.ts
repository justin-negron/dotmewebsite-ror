// Domain models matching Alba resource output

export interface Project {
  id: number
  title: string
  description: string
  tech_stack: string[]
  featured: boolean
  display_order: number
  github_url: string | null
  live_url: string | null
  image_url: string | null
  created_at: string
  updated_at: string
}

export interface Experience {
  id: number
  company: string
  position: string
  description: string
  technologies: string[]
  display_order: number
  current: boolean
  duration: string
  start_date: string
  end_date: string | null
  created_at: string
  updated_at: string
}

export interface BlogPost {
  id: number
  title: string
  slug: string
  content: string
  published: boolean
  tags: string[]
  view_count: number
  reading_time: number
  excerpt: string
  published_at: string | null
  created_at: string
  updated_at: string
}

export interface Contact {
  id: number
  name: string
  email: string
  subject: string
  message: string
  status: string
  created_at: string
}

export interface PageView {
  id: number
  path: string
  browser_name: string
  created_at: string
}

// Input types for mutations

export interface ProjectInput {
  title: string
  description: string
  tech_stack: string[]
  featured?: boolean
  display_order?: number
  github_url?: string
  live_url?: string
  image_url?: string
}

export interface ExperienceInput {
  company: string
  position: string
  description: string
  technologies: string[]
  display_order?: number
  start_date: string
  end_date?: string
  current?: boolean
}

export interface BlogPostInput {
  title: string
  content: string
  published?: boolean
  tags?: string[]
  slug?: string
}

export interface ContactFormData {
  name: string
  email: string
  subject?: string
  message: string
}

export interface PageViewData {
  path: string
  referrer?: string | null
  user_agent?: string | null
}

export interface AnalyticsStats {
  total_page_views: number
  unique_visitors?: number
  views_by_page?: Record<string, number>
  views_by_date?: Record<string, number>
}
