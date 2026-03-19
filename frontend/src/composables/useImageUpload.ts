import { ref } from 'vue'
import { adminUploadsApi } from '@/services/admin'

const ALLOWED_TYPES = [
  'image/jpeg',
  'image/png',
  'image/gif',
  'image/webp',
  'image/svg+xml',
]
const MAX_SIZE = 5 * 1024 * 1024 // 5 MB

export function useImageUpload() {
  const uploading = ref(false)
  const progress = ref(0)
  const error = ref<string | null>(null)

  async function uploadFile(file: File): Promise<string | null> {
    error.value = null

    if (!ALLOWED_TYPES.includes(file.type)) {
      error.value = `Unsupported file type: ${file.type}`
      return null
    }

    if (file.size > MAX_SIZE) {
      error.value = `File too large. Maximum size is 5 MB.`
      return null
    }

    uploading.value = true
    progress.value = 0

    try {
      // Get presigned URL from backend
      const result = await adminUploadsApi.getPresignedUrl(file.name, file.type)
      const { presigned_url, public_url } = result.data

      // Upload directly to S3 via XMLHttpRequest for progress tracking
      await new Promise<void>((resolve, reject) => {
        const xhr = new XMLHttpRequest()

        xhr.upload.addEventListener('progress', (e) => {
          if (e.lengthComputable) {
            progress.value = Math.round((e.loaded / e.total) * 100)
          }
        })

        xhr.addEventListener('load', () => {
          if (xhr.status >= 200 && xhr.status < 300) {
            resolve()
          } else {
            reject(new Error(`Upload failed with status ${xhr.status}`))
          }
        })

        xhr.addEventListener('error', () => reject(new Error('Network error during upload')))
        xhr.addEventListener('abort', () => reject(new Error('Upload cancelled')))

        xhr.open('PUT', presigned_url)
        xhr.setRequestHeader('Content-Type', file.type)
        xhr.send(file)
      })

      progress.value = 100
      return public_url
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Upload failed'
      return null
    } finally {
      uploading.value = false
    }
  }

  return {
    uploading,
    progress,
    error,
    uploadFile,
  }
}
