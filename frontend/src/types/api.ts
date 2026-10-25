export interface ApiSuccessResponse<T> {
  success: true
  data: T
  meta?: PaginationMeta
}

export interface ApiErrorResponse {
  success: false
  message: string
  /** Rails sends full messages, e.g. ["Email is invalid"]. */
  errors?: string[] | null
}

export interface PaginationMeta {
  current_page: number
  total_pages: number
  total_count: number
  per_page: number
}

export interface ApiError {
  message: string
  errors: string[] | null
  status: number | null
}
