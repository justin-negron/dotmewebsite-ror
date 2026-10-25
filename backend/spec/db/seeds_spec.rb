require 'rails_helper'

RSpec.describe 'db/seeds.rb' do
  def load_seeds
    expect { Rails.application.load_seed }.to output.to_stdout
  end

  around do |example|
    original = ENV.slice('ADMIN_EMAIL', 'ADMIN_PASSWORD')
    ENV['ADMIN_EMAIL'] = 'seed-admin@example.com'
    ENV['ADMIN_PASSWORD'] = 'seed-admin-password-123'
    example.run
  ensure
    %w[ADMIN_EMAIL ADMIN_PASSWORD].each { |key| ENV[key] = original[key] }
  end

  it 'creates the admin from ADMIN_EMAIL and ADMIN_PASSWORD' do
    load_seeds
    expect(Admin.pluck(:email)).to eq([ 'seed-admin@example.com' ])
  end

  it 'aborts when there is no admin and ADMIN_PASSWORD is unset' do
    ENV.delete('ADMIN_PASSWORD')
    expect { Rails.application.load_seed }.to raise_error(SystemExit).and output.to_stdout
  end

  it 'seeds only real portfolio content' do
    load_seeds
    expect(Project.count).to eq(4)
    expect(Experience.count).to eq(7)
    expect(Experience.pluck(:company)).to include('University of Nevada, Las Vegas',
                                                  'Georgia Institute of Technology')
  end

  it 'reflects the current career timeline' do
    travel_to(Date.new(2026, 10, 11)) do
      load_seeds
      bofa = Experience.where(company: 'Bank of America').index_by(&:position)

      expect(bofa['Software Engineer II']).to be_current
      expect(bofa['Site Reliability Engineer'].duration).to eq('February 2024 - July 2026')
      expect(bofa).not_to have_key('Software Engineer')
      expect(Experience.find_by(company: 'Georgia Institute of Technology').duration)
        .to eq('Incoming Fall 2027')
    end
  end

  it 'creates no placeholder blog posts, contacts, or page views' do
    load_seeds
    expect(BlogPost.count).to eq(0)
    expect(Contact.count).to eq(0)
    expect(PageView.count).to eq(0)
  end

  it 'contains none of the old phantom records' do
    load_seeds
    expect(Experience.where(company: [ 'Florida Atlantic University', 'Broward College' ])).to be_empty
  end

  it 'is idempotent' do
    load_seeds
    counts = [ Admin.count, Project.count, Experience.count ]
    load_seeds
    expect([ Admin.count, Project.count, Experience.count ]).to eq(counts)
  end

  it 'links the portfolio project nowhere, gives the school projects a slideshow, and points the bot at its paper' do
    load_seeds
    portfolio = Project.find_by!(title: 'This Portfolio Website')
    expect(portfolio.github_url).to be_nil
    expect(portfolio.live_url).to be_nil

    swarm = Project.find_by!(title: 'Autonomous Robot Swarm')
    bot = Project.find_by!(title: 'University Discord Bot')
    expect(swarm.media_urls.size).to eq(6)
    expect(bot.media_urls.size).to eq(3)
    expect(portfolio.media_urls).to eq([
      'https://assets.justinnegron.dev/projects/portfolio-website/01-overview-v3.webp#light-only',
      'https://assets.justinnegron.dev/projects/portfolio-website/01-overview-dark.webp#dark-only'
    ])
    expect(swarm.media_urls + bot.media_urls + portfolio.media_urls)
      .to all(start_with('https://assets.justinnegron.dev/projects/'))

    expect(bot.paper_url).to eq('https://doi.org/10.1007/978-3-032-27214-0_44')
    expect(swarm.paper_url).to be_nil
  end

  it 'does not overwrite records edited through the admin panel' do
    create(:project, title: 'This Portfolio Website', description: 'Edited in admin')
    load_seeds
    expect(Project.find_by(title: 'This Portfolio Website').description).to eq('Edited in admin')
  end
end
