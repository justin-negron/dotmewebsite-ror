# Clear existing data (only in development)
if Rails.env.development?
  puts "Clearing existing data..."
  PageView.destroy_all
  Contact.destroy_all
  BlogPost.destroy_all
  Experience.destroy_all
  Project.destroy_all
  puts "✓ Data cleared"
end

puts "\n=== Seeding Database ==="

# ============================
# PROJECTS
# ============================
puts "\nCreating projects..."

projects_data = [
  {
    title: "Proxy Management Company",
    description: "Discord bot for running a proxy company.",
    tech_stack: ["Discord.js", "Node.js"],
    github_url: "https://github.com/justin-negron/ProxyDiscordCompany",
    live_url: nil,
    featured: false,
    display_order: 1
  },
  {
    title: "Blackjack Emulator",
    description: "Practice gambling without losing money.",
    tech_stack: ["SystemVerilog", "DE2-115 FPGA", "ModelSim"],
    github_url: "https://github.com/justin-negron/BlackJack-FPGA",
    live_url: nil, # update this later with the blog of this project
    featured: false,
    display_order: 2
  },
  {
    title: "Logic Gates using MOSFETs",
    description: "Creating logic gates without the assistance of gates.",
    tech_stack: ["Wires :)"],
    github_url: nil,
    live_url: nil, # update this later with the blog of this project
    featured: false,
    display_order: 3
  },
  {
    title: "First Portfolio Website",
    description: "A short and sweet portfolio to showcase projects.",
    tech_stack: ["JavaScript", "HTML", "CSS", "AWS"],
    github_url: "https://github.com/justin-negron/dotmewebsite",
    live_url: "https://justinnegron.me", # update this later with a route within justinnegron.dev to show the old website
    featured: false,
    display_order: 4
  },
  {
    title: "University Discord Bot",
    description: "Normalize the use of Discord by all Professors.",
    tech_stack: ["TypeScript", "Python", "Postgres", "Discord.js"],
    github_url: nil,
    live_url: nil, # update this later with the blog of this project
    featured: true,
    display_order: 5
  },
  {
    title: "Autonomous Mobile Robot Swarm",
    description: "Space exploration :).",
    tech_stack: ["C/C#", "STM32", "RTOS", "ARM"],
    github_url: nil,
    live_url: nil, # update this later with the blog of this project
    featured: true,
    display_order: 6
  },
  {
    title: "This Portfolio Website",
    description: "A renewed portfolio utilizing modern tech practices.",
    tech_stack: ["Ruby on Rails", "Postgres", "AWS Aurora", "Vue.js" ,"REST"],
    github_url: "https://github.com/justin-negron/dotmewebsite-ror",
    live_url: "https://justinnegron.dev",
    featured: true,
    display_order: 7
  }
]

projects_data.each do |project_data|
  project = Project.create!(project_data)
  puts "  ✓ Created: #{project.title}"
end

puts "Created #{Project.count} projects"

# ============================
# EXPERIENCES
# ============================
puts "\nCreating work experiences..."

experiences_data = [
  {
    company: "Bank of America",
    position: "Software Engineer",
    start_date: Date.new(2024, 2, 26),
    end_date: nil,
    description: "Efforts are focused in Performance, Observability, and Site Reliability.",
    technologies: ["Java", "C", "Python", "Vugen", "BitBucket", "Splunk", "Dynatrace"],
    display_order: 1,
    experience_type: "work"
  },
  {
    company: "Bank of America",
    position: "Software Engineer Intern",
    start_date: Date.new(2023, 6, 2),
    end_date: Date.new(2023, 8, 10),
    description: "Simulated user behavior using VuGen scripts for system-wide performance testing on LoadRunner Enterprise. Maintained test environments to accurately replicate production workloads and ensure reliable performance. Enhanced Python scripts to integrate Dynatrace API analytics, increasing observability and test accuracy.",
    technologies: ["C", "Python", "Vugen", "Dynatrace"],
    display_order: 2,
    experience_type: "work"
  },
  {
    company: "Fire by Design",
    position: "Software Engineer Intern",
    start_date: Date.new(2022, 5, 15),
    end_date: Date.new(2023, 1, 10),
    description: "Developed a Ruby on Rails web application to replace manual Excel inventory management. Added a CSV import to upload existing Excel spreadsheets to populate DB tables. Implemented a binary search algorithm to search all Products and relative Parts.",
    technologies: ["Ruby on Rails", "Postgres", "Bootstrap"],
    display_order: 3,
    experience_type: "work"
  },
  {
    company: "Westinis Inc",
    position: "Software Engineer Intern",
    start_date: Date.new(2021, 6, 1),
    end_date: Date.new(2021, 8, 10),
    description: "Extracted geo-location data points from IoT devices and Smartphones with Blazor WebAssembly. Calibrated geo-location data points to be displayed on XAML Map Interface. Evaluated if existing Razor pages could be upgraded to Blazor pages.",
    technologies: ["C#", ".NET", "Blazor", "Azure"],
    display_order: 4,
    experience_type: "work"
  },
  # Education
  {
    company: "Florida Atlantic University",
    position: "B.S. Computer Engineering",
    start_date: Date.new(2020, 8, 1),
    end_date: Date.new(2023, 12, 15),
    description: "Concentrated in embedded systems and digital design. Completed capstone project on autonomous mobile robot swarm using STM32 microcontrollers and RTOS. Active member of the Engineering Society.",
    technologies: ["C/C++", "SystemVerilog", "MATLAB", "ARM", "RTOS", "Python"],
    display_order: 5,
    experience_type: "education"
  },
  {
    company: "Broward College",
    position: "A.A. General Studies",
    start_date: Date.new(2018, 8, 1),
    end_date: Date.new(2020, 5, 15),
    description: "Completed core coursework with a focus on mathematics and sciences. Dean's List recipient. Transferred to Florida Atlantic University for Computer Engineering.",
    technologies: ["Calculus", "Physics", "Chemistry", "Programming Fundamentals"],
    display_order: 6,
    experience_type: "education"
  }
]

experiences_data.each do |exp_data|
  experience = Experience.create!(exp_data)
  status = experience.current? ? "(Current)" : ""
  puts "  ✓ Created: #{experience.company} - #{experience.position} #{status}"
end

puts "Created #{Experience.count} experiences"

# ============================
# BLOG POSTS
# ============================
puts "\nCreating blog posts..."

blog_posts_data = [
  {
    title: "Find My History",
    content: "The story of when my Onewheel was stolen.",
    tags: ["Onewheel", "Theft", "Github"],
    published: true,
    published_at: 2.weeks.ago
  },
  {
    title: "Autonomous Robot Swarm - Computer Engineering Capstone",
    content: "In this tutorial, I'll walk you through building a modern full-stack application using Ruby on Rails for the backend API and Vue.js for the frontend.\n\n## Why This Stack?\n\nRails provides a robust, convention-over-configuration framework perfect for building RESTful APIs quickly. Vue.js offers a reactive, component-based approach to building user interfaces that's both powerful and easy to learn.\n\n## Setting Up the Backend\n\nFirst, let's create a new Rails API. This creates a lightweight Rails application optimized for API development. We're using PostgreSQL because it's production-ready and offers advanced features we might need later.\n\n## Database Design\n\nStart by thinking about your data models. For a blog application, we might have Posts, Comments, and Users. Create your migrations and models with proper associations and validations.\n\n## API Design Best Practices\n\n1. Use RESTful conventions\n2. Version your API (e.g., /api/v1/posts)\n3. Implement proper error handling\n4. Use serializers for JSON responses\n5. Add authentication with JWT\n\n## Frontend with Vue.js\n\nVue's component system makes it easy to build reusable UI elements. Use Vuex for state management and Vue Router for navigation.\n\n## Deployment\n\nConsider deploying your Rails API on AWS ECS and your Vue frontend on CloudFront for optimal performance and scalability. Stay tuned for a detailed tutorial series on this topic!",
    tags: ["Computer Engineering", "Robot", "RTOS", "STM32", "RSSI", "Capstone"],
    published: true,
    published_at: 2.weeks.ago
  },
  {
    title: "University Discord Bot - Computer Science Capstone",
    content: "JSON Web Tokens (JWT) are a popular way to handle authentication in modern web applications, especially for API-based architectures.\n\n## What is JWT?\n\nA JWT is a compact, URL-safe token that contains claims about a user. It consists of three parts: Header (token type and hashing algorithm), Payload (claims/user data), and Signature (verifies integrity).\n\n## Why Use JWT?\n\n- Stateless authentication\n- Works great with APIs\n- Can be used across different domains\n- Contains user information without database lookups\n\n## Implementing JWT in Rails\n\nCreate a JsonWebToken class to handle encoding and decoding. Use a strong secret key from your Rails credentials.\n\n## Security Considerations\n\n1. Always use HTTPS in production\n2. Set reasonable expiration times\n3. Store tokens securely on the client\n4. Implement refresh tokens for better UX\n5. Never store sensitive data in the payload\n\n## Best Practices\n\n- Use HTTP-only cookies for web applications\n- Implement token refresh logic\n- Add rate limiting to prevent brute force attacks\n- Log authentication attempts\n- Use strong secret keys\n\nJWT authentication provides a solid foundation for securing your Rails API while keeping it stateless and scalable.",
    tags: ["Computer Science", "Discord", "Bot", "Capstone"],
    published: true,
    published_at: 1.month.ago
  },
  {
    title: "Logic Gates using MOSFETs",
    content: "One of the most common performance bottlenecks in Rails applications is inefficient database queries. Let's explore how to identify and fix them.\n\n## The N+1 Query Problem\n\nThis is the most common issue. When you iterate over records and access associations, each iteration triggers a new database query. Use eager loading with includes() to load all data upfront.\n\n## Tools for Detection\n\nUse the Bullet gem in development. It will alert you when you have N+1 queries or unused eager loading.\n\n## Indexing\n\nAdd indexes to foreign keys and frequently queried columns. This dramatically speeds up lookups and joins.\n\n## Query Optimization Techniques\n\n1. Use select to only fetch needed columns\n2. Use pluck for simple data extraction\n3. Implement counter caches for associations\n4. Use database views for complex queries\n5. Consider read replicas for analytics\n\n## Caching\n\nImplement caching at multiple levels: Fragment caching for views, Russian doll caching for nested data, Low-level caching with Redis, and HTTP caching with ETags.\n\nRemember: Measure before optimizing. Use tools like New Relic or Skylight to identify actual bottlenecks.",
    tags: ["Electrical Engineering", "Gates", "MOSFET"],
    published: true,
    published_at: 3.weeks.ago
  },
  {
    title: "Blackjack Emulator",
    content: "This is a draft post about my journey in web development. Coming soon!\n\nI'll cover topics like:\n- How I got started\n- Challenges I faced\n- Resources that helped me\n- Advice for beginners\n- Where I'm heading next\n\nStay tuned!",
    tags: ["Computer Engineering", "FPGA", "DE2", "Altera", "Verilog", "ModelSim"],
    published: false,
    published_at: nil
  }
]

blog_posts_data.each do |post_data|
  post = BlogPost.create!(post_data)
  status = post.published? ? "✓ Published" : "○ Draft"
  puts "  #{status}: #{post.title}"
end

puts "Created #{BlogPost.count} blog posts (#{BlogPost.published.count} published)"

# ============================
# SAMPLE CONTACTS (for testing)
# ============================
puts "\nCreating sample contact submissions..."

contacts_data = [
  {
    name: "Sarah Johnson",
    email: "sarah.j@example.com",
    subject: "Freelance Opportunity",
    message: "Hi Justin, I came across your portfolio and was impressed by your work. We're looking for a freelance developer for a 3-month project. Would you be interested in discussing this?",
    status: "new"
  },
  {
    name: "Mike Chen",
    email: "mchen@techcorp.com",
    subject: "Speaking Engagement",
    message: "Hello! We're organizing a tech conference and would love to have you speak about full-stack development. Are you available in March?",
    status: "read"
  }
]

contacts_data.each do |contact_data|
  contact = Contact.create!(contact_data)
  puts "  ✓ Created: Contact from #{contact.name}"
end

puts "Created #{Contact.count} contact submissions"

# ============================
# SAMPLE ANALYTICS (for testing)
# ============================
puts "\nCreating sample page views..."

# Simulate page views over the last 30 days
paths = ["/", "/projects", "/blog", "/contact"]
user_agents = [
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
  "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
]

30.times do |i|
  rand(5..15).times do
    PageView.create!(
      path: paths.sample,
      user_agent: user_agents.sample,
      ip_address: "#{rand(1..255)}.#{rand(1..255)}.#{rand(1..255)}.#{rand(1..255)}",
      referrer: ["https://google.com", "https://twitter.com", nil].sample,
      created_at: i.days.ago + rand(0..23).hours
    )
  end
end

puts "Created #{PageView.count} page views"

# ============================
# SUMMARY
# ============================
puts "\n=== Seeding Complete ==="
puts "Projects: #{Project.count} (#{Project.featured.count} featured)"
puts "Experiences: #{Experience.count} (#{Experience.current.count} current)"
puts "Blog Posts: #{BlogPost.count} (#{BlogPost.published.count} published)"
puts "Contacts: #{Contact.count} (#{Contact.where(status: 'new').count} unread)"
puts "Page Views: #{PageView.count}"
puts "\n✓ Database seeded successfully!"