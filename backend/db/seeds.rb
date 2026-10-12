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

projects_data = [
  {
    title: "First Portfolio Website",
    description: "A short and sweet portfolio to showcase projects.",
    tech_stack: ["JavaScript", "HTML", "CSS", "AWS"],
    github_url: "https://github.com/justin-negron/dotmewebsite",
    live_url: "https://justinnegron.me",
    featured: false,
    display_order: 4
  },
  {
    title: "University Discord Bot",
    description: "Normalize the use of Discord by all Professors.",
    tech_stack: ["TypeScript", "Python", "Postgres", "Discord.js"],
    featured: true,
    display_order: 5
  },
  {
    title: "Autonomous Mobile Robot Swarm",
    description: "Space exploration :).",
    tech_stack: ["C/C#", "STM32", "RTOS", "ARM"],
    featured: true,
    display_order: 6
  },
  {
    title: "This Portfolio Website",
    description: "I just wanted to refresh my portfolio website using modern tech practices.",
    tech_stack: ["Ruby", "Rails", "Vue", "TypeScript", "Tailwind CSS", "Terraform", "CircleCI", "AWS"],
    github_url: "https://github.com/justin-negron/dotmewebsite-ror",
    live_url: "https://justinnegron.dev",
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
    position: "Software Engineer",
    start_date: Date.new(2024, 2, 26),
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
    description: "Simulated user behavior using VuGen scripts for system-wide performance testing on LoadRunner Enterprise.\n" \
                 "Maintained test environments to accurately replicate production workloads and ensure reliable performance.\n" \
                 "Enhanced Python scripts to integrate Dynatrace API analytics, increasing observability and test accuracy.",
    technologies: ["C", "Python", "Vugen", "Dynatrace"],
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
    technologies: ["Ruby on Rails", "Postgres", "Bootstrap"],
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
    technologies: ["C#", ".NET", "Blazor", "Azure"],
    display_order: 4,
    experience_type: "work"
  },
  {
    company: "University of Nevada, Las Vegas",
    position: "B.S in Computer Science\nB.S.E in Computer Engineering",
    start_date: Date.new(2019, 1, 1),
    end_date: Date.new(2023, 12, 15),
    description: "Minor in Mathematical Sciences\nConcentrations in Intelligent Systems and Computer Networks",
    technologies: ["C/C++", "Java", "Python", "Visual Studio Code", "Linux", "MATLAB", "SystemVerilog",
                   "DSA", "AWS", "TypeScript", "GitHub", "PostgreSQL"],
    display_order: 5,
    experience_type: "education"
  },
  {
    company: "Georgia Institute of Technology",
    position: "M.S in Computer Science",
    start_date: Date.new(2026, 8, 15),
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
