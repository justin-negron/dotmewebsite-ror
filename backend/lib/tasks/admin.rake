namespace :admin do
  desc 'Create admin user (interactive or via ADMIN_EMAIL/ADMIN_PASSWORD env vars)'
  task create: :environment do
    if Admin.exists?
      puts "Admin already exists: #{Admin.first.email}"
      puts "To reset password, run: bin/rails admin:reset"
      exit
    end

    email = ENV.fetch('ADMIN_EMAIL') do
      print 'Admin email: '
      $stdin.gets.chomp
    end

    password = ENV.fetch('ADMIN_PASSWORD') do
      print 'Admin password (min 12 chars): '
      $stdin.gets.chomp
    end

    admin = Admin.create!(email: email, password: password)
    puts "Admin created: #{admin.email}"
  end

  desc 'Reset admin password (via ADMIN_PASSWORD env var or interactive)'
  task reset: :environment do
    admin = Admin.first!
    password = ENV.fetch('ADMIN_PASSWORD') do
      print "New password for #{admin.email} (min 12 chars): "
      $stdin.gets.chomp
    end

    admin.update!(password: password)
    admin.invalidate_refresh_token!
    puts "Password reset and sessions invalidated for #{admin.email}"
  end
end
