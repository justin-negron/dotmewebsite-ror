import {
  projectsApi,
  experiencesApi,
  blogApi,
  contactsApi,
  analyticsApi,
} from './services'

async function testAll() {
  console.log('🧪 Testing all API endpoints...')
  
  try {
    // Test Projects
    console.log('\n📦 Testing Projects API...')
    const projects = await projectsApi.getProjects()
    const projectsArray = Array.isArray(projects) ? projects : (projects.data || [])
    console.log(`✅ Found ${projectsArray.length} projects`)
    if (projectsArray.length > 0) {
      console.log('   First project:', projectsArray[0].title)
    }
    
    // Test Experiences
    console.log('\n💼 Testing Experiences API...')
    const experiences = await experiencesApi.getExperiences()
    const experiencesArray = Array.isArray(experiences) ? experiences : (experiences.data || [])
    console.log(`✅ Found ${experiencesArray.length} experiences`)
    if (experiencesArray.length > 0) {
      console.log('   First experience:', experiencesArray[0].company)
    }
    
    // Test Blog
    console.log('\n📝 Testing Blog API...')
    const posts = await blogApi.getBlogPosts()
    const postsArray = Array.isArray(posts) ? posts : (posts.data || [])
    console.log(`✅ Found ${postsArray.length} blog posts`)
    if (postsArray.length > 0) {
      console.log('   First post:', postsArray[0].title)
    }
    
    // Test Analytics (optional - may not exist yet)
    console.log('\n📊 Testing Analytics API...')
    try {
      await analyticsApi.trackPageView({ path: '/test' })
      console.log('✅ Page view tracked')
    } catch (error) {
      if (error.status === 404) {
        console.log('⚠️  Analytics endpoint not implemented yet (this is OK)')
      } else {
        throw error
      }
    }
    
    console.log('\n🎉 All tests passed!')
  } catch (error) {
    console.error('\n❌ Test failed:', error)
    console.error('Error details:', {
      message: error.message,
      status: error.status,
      errors: error.errors
    })
  }
}

testAll()