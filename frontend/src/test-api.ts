import { projectsApi, experiencesApi, blogApi, analyticsApi } from './services'
import type { ApiError } from '@/types'

async function testAll() {
  console.log('Testing all API endpoints...')

  try {
    console.log('\nTesting Projects API...')
    const projects = await projectsApi.getProjects()
    const projectsArray = Array.isArray(projects) ? projects : projects.data || []
    console.log(`Found ${projectsArray.length} projects`)
    if (projectsArray.length > 0) {
      console.log('   First project:', projectsArray[0].title)
    }

    console.log('\nTesting Experiences API...')
    const experiences = await experiencesApi.getExperiences()
    const experiencesArray = Array.isArray(experiences) ? experiences : experiences.data || []
    console.log(`Found ${experiencesArray.length} experiences`)
    if (experiencesArray.length > 0) {
      console.log('   First experience:', experiencesArray[0].company)
    }

    console.log('\nTesting Blog API...')
    const posts = await blogApi.getBlogPosts()
    const postsArray = Array.isArray(posts) ? posts : posts.data || []
    console.log(`Found ${postsArray.length} blog posts`)
    if (postsArray.length > 0) {
      console.log('   First post:', postsArray[0].title)
    }

    console.log('\nTesting Analytics API...')
    try {
      await analyticsApi.trackPageView({ path: '/test' })
      console.log('Page view tracked')
    } catch (error) {
      const apiError = error as ApiError
      if (apiError.status === 404) {
        console.log('Analytics endpoint not implemented yet (this is OK)')
      } else {
        throw error
      }
    }

    console.log('\nAll tests passed!')
  } catch (error) {
    const apiError = error as ApiError
    console.error('\nTest failed:', error)
    console.error('Error details:', {
      message: apiError.message,
      status: apiError.status,
      errors: apiError.errors,
    })
  }
}

testAll()
