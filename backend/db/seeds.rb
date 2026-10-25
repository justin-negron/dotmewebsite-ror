# Seeds the admin user and the real portfolio content shown on justinnegron.dev.
# Records are matched by natural key (project title; experience company + start
# date) and existing ones are never modified, so re-running neither duplicates
# nor overwrites. A record whose key was changed or that was deleted in admin
# would be re-created, so production only runs this on an empty database
# (via db:prepare).
# No sample blog posts, contacts, or page views: those come from real use.

puts "\n=== Seeding Database ==="

# ============================
# ADMIN USER
# ============================
puts "\nCreating admin user..."

if Admin.count.zero?
  Admin.create!(
    email: ENV.fetch('ADMIN_EMAIL', 'admin@justinnegron.dev'),
    password: ENV.fetch('ADMIN_PASSWORD') { abort 'Set ADMIN_PASSWORD (min 12 chars) to seed the admin user.' }
  )
  puts "  ✓ Admin created (email: #{Admin.first.email})"
else
  puts "  ○ Admin already exists, skipping"
end

# ============================
# PROJECTS
# ============================
puts "\nCreating projects..."

assets = "https://assets.justinnegron.dev/projects"

projects_data = [
  {
    title: "First Portfolio Website",
    description: "A short and sweet portfolio to showcase projects.",
    tech_stack: [ "JavaScript", "HTML", "CSS", "AWS" ],
    github_url: "https://github.com/justin-negron/dotmewebsite",
    live_url: "https://justinnegron.me",
    featured: false,
    display_order: 4
  },
  {
    title: "University Discord Bot",
    description: "Normalize the use of Discord to encourage student interactions, while being user-friendly for Professors.",
    tech_stack: [ "TypeScript", "Python", "Postgres", "Discord.js" ],
    media_urls: [
      "#{assets}/university-discord-bot/01-landing-page.webp",
      "#{assets}/university-discord-bot/02-poster.webp",
      "#{assets}/university-discord-bot/03-first-place-award.webp"
    ],
    # Later work on the bot, published at ITNG 2026 (Springer). The chapter's
    # acknowledgements credit the spring 2023 senior design team.
    paper_url: "https://doi.org/10.1007/978-3-032-27214-0_44",
    featured: true,
    display_order: 5
  },
  {
    title: "Autonomous Robot Swarm",
    description: "Triangulate the position of rovers using RSSI. Space exploration :)",
    tech_stack: [ "C/C#", "STM32", "RTOS", "ARM" ],
    media_urls: [
      "#{assets}/autonomous-robot-swarm/01-robot-lineup.webp",
      "#{assets}/autonomous-robot-swarm/02-numbered-robots.webp",
      "#{assets}/autonomous-robot-swarm/03-showcase-table.webp",
      "#{assets}/autonomous-robot-swarm/04-lab-build.webp",
      "#{assets}/autonomous-robot-swarm/05-poster-v2.webp",
      "#{assets}/autonomous-robot-swarm/06-first-place-award.webp"
    ],
    featured: true,
    display_order: 6
  },
  {
    title: "This Portfolio Website",
    description: "A refresh of my portfolio website using modern tech practices.",
    tech_stack: [ "Ruby", "Rails", "Vue", "TypeScript", "Tailwind CSS", "Terraform", "CircleCI", "AWS" ],
    # Light and dark renderings of the same diagram; the card shows the one
    # matching the visitor's theme (the #...-only fragment never reaches the CDN).
    media_urls: [
      "#{assets}/portfolio-website/01-overview-v3.webp#light-only",
      "#{assets}/portfolio-website/01-overview-dark.webp#dark-only"
    ],
    featured: true,
    display_order: 7
  }
]

projects_data.each do |attrs|
  project = Project.find_or_create_by!(title: attrs[:title]) { |p| p.assign_attributes(attrs) }
  puts "  ✓ #{project.title}"
end

# ============================
# EXPERIENCE & EDUCATION
# ============================
puts "\nCreating experiences..."

experiences_data = [
  {
    company: "Bank of America",
    position: "Software Engineer II",
    start_date: Date.new(2026, 7, 16),
    description: "Build internal AI tools, including agents that help teams ship releases and security fixes faster.\n" \
                 "Engage with teams to adopt those tools and fit them into their SDLC.\n" \
                 "Track dependency health across the organization's codebases to know where automation can benefit the most.",
    technologies: [ "AI Agents", "LLMs", "REST APIs", "Jira", "Copilot Studio", "Moderne" ],
    display_order: 1,
    experience_type: "work"
  },
  {
    company: "Bank of America",
    position: "Site Reliability Engineer",
    start_date: Date.new(2024, 2, 26),
    end_date: Date.new(2026, 7, 15),
    description: "Performance engineering and site reliability for enterprise banking apps serving 2M+ users.\n" \
                 "Worked out each release's load tests with Product, Dev, and Production Support, and tuned them against real production traffic so the results meant something.\n" \
                 "Built Python and Bash automation plus an in-house test orchestrator, so multi-day manual validation became something people could kick off themselves.\n" \
                 "Placed 1st of 22 teams at a 2024 internal hackathon and 3rd of 400+ at the 2025 Improve-a-thon.",
    technologies: [ "Python", "Bash", "SQL", "Java", "C", "LoadRunner", "JMeter", "Dynatrace", "Splunk" ],
    display_order: 1,
    experience_type: "work"
  },
  {
    company: "Bank of America",
    position: "Software Engineer Intern",
    start_date: Date.new(2023, 6, 2),
    end_date: Date.new(2023, 8, 10),
    description: "Simulated user behavior using VuGen scripts for system-wide performance testing on LoadRunner Enterprise.\n" \
                 "Maintained test environments to accurately replicate production workloads and ensure reliable performance.\n" \
                 "Enhanced Python scripts to integrate Dynatrace API analytics, increasing observability and test accuracy.",
    technologies: [ "C", "Python", "Vugen", "Dynatrace" ],
    display_order: 2,
    experience_type: "work"
  },
  {
    company: "Fire by Design",
    position: "Software Engineer Intern",
    start_date: Date.new(2022, 5, 15),
    end_date: Date.new(2023, 1, 10),
    description: "Developed a Ruby on Rails web application to replace manual Excel inventory management.\n" \
                 "Added a CSV import to upload existing Excel spreadsheets to populate DB tables.\n" \
                 "Implemented a binary search algorithm to search all Products and relative Parts.",
    technologies: [ "Ruby on Rails", "Postgres", "Bootstrap" ],
    display_order: 3,
    experience_type: "work"
  },
  {
    company: "Westinis Inc",
    position: "Software Engineer Intern",
    start_date: Date.new(2021, 6, 1),
    end_date: Date.new(2021, 8, 10),
    description: "Extracted geo-location data points from IoT devices and Smartphones with Blazor WebAssembly.\n" \
                 "Calibrated geo-location data points to be displayed on XAML Map Interface.\n" \
                 "Evaluated if existing Razor pages could be upgraded to Blazor pages.",
    technologies: [ "C#", ".NET", "Blazor", "Azure" ],
    display_order: 4,
    experience_type: "work"
  },
  {
    company: "University of Nevada, Las Vegas",
    position: "B.S in Computer Science\nB.S.E in Computer Engineering",
    start_date: Date.new(2019, 1, 1),
    end_date: Date.new(2023, 12, 15),
    description: "Minor in Mathematical Sciences\nConcentrations in Intelligent Systems and Computer Networks",
    technologies: [ "C/C++", "Java", "Python", "Visual Studio Code", "Linux", "MATLAB", "SystemVerilog",
                   "DSA", "AWS", "TypeScript", "GitHub", "PostgreSQL" ],
    display_order: 5,
    experience_type: "education"
  },
  {
    company: "Georgia Institute of Technology",
    position: "M.S in Computer Science",
    start_date: Date.new(2027, 8, 15),
    description: "Specialization in Computing Systems",
    technologies: [],
    display_order: 5,
    experience_type: "education"
  }
]

experiences_data.each do |attrs|
  experience = Experience.find_or_create_by!(company: attrs[:company], start_date: attrs[:start_date]) do |e|
    e.assign_attributes(attrs)
  end
  puts "  ✓ #{experience.company} - #{experience.position.lines.first.strip}"
end

# ============================
# SUMMARY
# ============================
puts "\n=== Seeding Complete ==="
puts "Admins: #{Admin.count}"
puts "Projects: #{Project.count} (#{Project.featured.count} featured)"
puts "Experiences: #{Experience.count} (#{Experience.current.count} current)"
