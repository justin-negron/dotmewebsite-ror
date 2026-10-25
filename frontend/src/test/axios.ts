import { AxiosError, AxiosHeaders } from 'axios'
import type { AxiosResponse, InternalAxiosRequestConfig } from 'axios'

export function ok<T>(config: InternalAxiosRequestConfig, data: T, status = 200): AxiosResponse<T> {
  return { data, status, statusText: 'OK', headers: new AxiosHeaders(), config }
}

export function httpError(
  config: InternalAxiosRequestConfig,
  status: number,
  data: unknown
): AxiosError {
  const response = { data, status, statusText: '', headers: new AxiosHeaders(), config }
  return new AxiosError(`HTTP ${status}`, 'ERR_BAD_REQUEST', config, {}, response)
}
