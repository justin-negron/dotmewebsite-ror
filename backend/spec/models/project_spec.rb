require 'rails_helper'

RSpec.describe Project, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:description) }

    %i[github_url live_url paper_url].each do |attr|
      it "accepts an http(s) #{attr}" do
        expect(build(:project, attr => 'https://example.com/path?q=1')).to be_valid
      end

      it "rejects a #{attr} with a javascript: prefix" do
        project = build(:project, attr => 'javascript:alert(1)//https://example.com')
        expect(project).not_to be_valid
        expect(project.errors[attr]).to be_present
      end

      it "rejects a #{attr} with an injected second line" do
        project = build(:project, attr => "https://example.com\njavascript:alert(1)")
        expect(project).not_to be_valid
      end
    end
  end

  describe 'media_urls' do
    it 'accepts a list of http(s) URLs in order' do
      project = build(:project, media_urls: [ 'https://cdn.example.com/1.webp', 'http://cdn.example.com/2.webp' ])
      expect(project).to be_valid
      expect(project.media_urls).to eq([ 'https://cdn.example.com/1.webp', 'http://cdn.example.com/2.webp' ])
    end

    it 'accepts a theme marker fragment on a media URL' do
      project = build(:project, media_urls: [ 'https://cdn.example.com/light.webp#light-only', 'https://cdn.example.com/dark.webp#dark-only' ])
      expect(project).to be_valid
    end

    it 'strips whitespace and drops blank entries before validating' do
      project = build(:project, media_urls: [ '  https://cdn.example.com/1.webp ', '', '   ', nil ])
      expect(project).to be_valid
      expect(project.media_urls).to eq([ 'https://cdn.example.com/1.webp' ])
    end

    it 'rejects a javascript: entry and names it in the error' do
      project = build(:project, media_urls: [ 'https://cdn.example.com/1.webp', 'javascript:alert(1)' ])
      expect(project).not_to be_valid
      expect(project.errors[:media_urls].first).to include('javascript:alert(1)')
    end

    it 'rejects an entry with an injected second line' do
      project = build(:project, media_urls: [ "https://cdn.example.com/1.webp\njavascript:alert(1)" ])
      expect(project).not_to be_valid
    end

    it "rejects more than #{Project::MAX_MEDIA_URLS} entries" do
      urls = (1..Project::MAX_MEDIA_URLS + 1).map { |i| "https://cdn.example.com/#{i}.webp" }
      project = build(:project, media_urls: urls)
      expect(project).not_to be_valid
      expect(project.errors[:media_urls]).to eq([ 'can have at most 12 entries' ])
    end

    it 'defaults to an empty array' do
      expect(Project.new.media_urls).to eq([])
    end
  end

  describe 'scopes' do
    let!(:featured_project) { create(:project, :featured) }
    let!(:regular_project) { create(:project) }

    it 'returns only featured projects' do
      expect(Project.featured).to include(featured_project)
      expect(Project.featured).not_to include(regular_project)
    end

    it 'orders by display_order and created_at' do
      project1 = create(:project, display_order: 2)
      project2 = create(:project, display_order: 1)

      expect(Project.ordered.first).to eq(project2)
    end
  end

  describe '#tech_stack_list' do
    it 'returns comma-separated tech stack' do
      project = create(:project, tech_stack: [ 'Ruby', 'Rails', 'PostgreSQL' ])
      expect(project.tech_stack_list).to eq('Ruby, Rails, PostgreSQL')
    end
  end

  describe 'display_order' do
    it 'assigns the next display_order on create when none is given' do
      create(:project, display_order: 7)
      expect(create(:project, display_order: nil).display_order).to eq(8)
    end
  end

  describe 'image_url column' do
    it 'stays in the schema until the next deploy drops it, but the model neither reads nor writes it' do
      expect(Project.connection.columns(:projects).map(&:name)).to include('image_url')
      expect(Project.column_names).not_to include('image_url')
    end

    it 'is not named in the INSERT for a new project' do
      inserts = []
      capture = ->(_name, _start, _finish, _id, payload) { inserts << payload[:sql] if payload[:sql].start_with?('INSERT') }
      ActiveSupport::Notifications.subscribed(capture, 'sql.active_record') { create(:project) }

      expect(inserts.size).to eq(1)
      expect(inserts.first).to include('"media_urls"')
      expect(inserts.first).not_to include('"image_url"')
    end
  end
end
