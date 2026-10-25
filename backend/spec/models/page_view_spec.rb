require 'rails_helper'

RSpec.describe PageView, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:path) }
  end

  describe 'scopes' do
    let!(:home_view) { create(:page_view, :home_page) }
    let!(:projects_view) { create(:page_view, :projects_page) }
    let!(:old_view) { create(:page_view, created_at: 2.days.ago) }

    it 'returns views for specific path' do
      expect(PageView.for_path('/')).to include(home_view)
      expect(PageView.for_path('/')).not_to include(projects_view)
    end

    it 'returns views in date range' do
      views = PageView.in_date_range(1.day.ago, Time.current)
      expect(views).to include(home_view)
      expect(views).not_to include(old_view)
    end

    it 'orders by most recent first' do
      expect(PageView.recent.first).to eq(projects_view)
    end
  end

  describe '.popular_pages' do
    before do
      create_list(:page_view, 5, path: '/')
      create_list(:page_view, 3, path: '/projects')
      create(:page_view, path: '/blog')
    end

    it 'returns most viewed pages' do
      popular = PageView.popular_pages(2)
      expect(popular.first.path).to eq('/')
      expect(popular.first.view_count).to eq(5)
    end
  end

  describe '.views_by_date' do
    it 'groups views by date' do
      travel_to Time.zone.local(2026, 1, 15, 12, 0, 0) do
        create_list(:page_view, 3, created_at: Time.current)
        create_list(:page_view, 2, created_at: 1.day.ago)

        views = PageView.views_by_date(7)
        expect(views[Date.current]).to eq(3)
        expect(views[1.day.ago.to_date]).to eq(2)
      end
    end
  end

  describe '.unique_visitors' do
    before do
      create(:page_view, visitor_hash: 'a' * 32)
      create(:page_view, visitor_hash: 'a' * 32)
      create(:page_view, visitor_hash: 'b' * 32)
    end

    it 'counts distinct visitor hashes' do
      expect(PageView.unique_visitors(30)).to eq(2)
    end
  end

  describe 'ip_address column' do
    it 'stays in the schema until the next deploy drops it, but the model neither reads nor writes it' do
      expect(PageView.connection.columns(:page_views).map(&:name)).to include('ip_address')
      expect(PageView.column_names).not_to include('ip_address')
    end
  end

  describe '.visitor_hash_for' do
    let(:day) { Date.new(2026, 1, 15) }
    let(:hash) { PageView.visitor_hash_for('203.0.113.7', day) }

    it 'gives the same 32-hex hash for the same address on the same day' do
      expect(hash).to match(/\A\h{32}\z/)
      expect(PageView.visitor_hash_for('203.0.113.7', day)).to eq(hash)
    end

    it 'changes with the address' do
      expect(PageView.visitor_hash_for('203.0.113.8', day)).not_to eq(hash)
    end

    it 'changes with the day' do
      expect(PageView.visitor_hash_for('203.0.113.7', day + 1)).not_to eq(hash)
    end

    it 'is keyed with a server secret, so it is not the plain digest of day and address' do
      expect(hash).not_to eq(Digest::SHA256.hexdigest("#{day}203.0.113.7")[0, 32])
    end
  end

  describe '.purge_older_than' do
    it 'refuses a retention under one day instead of deleting everything' do
      create(:page_view)
      expect { PageView.purge_older_than(0) }.to raise_error(ArgumentError, /at least 1 day/)
      expect { PageView.purge_older_than('abc') }.to raise_error(ArgumentError)
      expect(PageView.count).to eq(1)
    end

    it 'deletes views older than the retention window and keeps newer ones' do
      create(:page_view, path: '/gone', created_at: 91.days.ago)
      create(:page_view, path: '/kept', created_at: 89.days.ago)

      PageView.purge_older_than(90)

      expect(PageView.pluck(:path)).to eq([ '/kept' ])
    end
  end

  describe '#browser_name' do
    it 'detects Chrome' do
      page_view = build(:page_view, user_agent: 'Mozilla/5.0 Chrome/120.0.0.0')
      expect(page_view.browser_name).to eq('Chrome')
    end

    it 'detects Safari' do
      page_view = build(:page_view, user_agent: 'Mozilla/5.0 Safari/537.36')
      expect(page_view.browser_name).to eq('Safari')
    end

    it 'detects Firefox' do
      page_view = build(:page_view, user_agent: 'Mozilla/5.0 Firefox/120.0')
      expect(page_view.browser_name).to eq('Firefox')
    end

    it 'returns Unknown for blank user agent' do
      page_view = build(:page_view, user_agent: nil)
      expect(page_view.browser_name).to eq('Unknown')
    end
  end

  describe '#browser_name edge cases' do
    it 'detects Edge from a real Chromium-based Edge user agent' do
      page_view = build(:page_view, user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0')
      expect(page_view.browser_name).to eq('Edge')
    end

    it 'detects Opera from a real Opera user agent' do
      page_view = build(:page_view, user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 OPR/106.0.0.0')
      expect(page_view.browser_name).to eq('Opera')
    end

    it 'returns Other for unrecognized browser' do
      page_view = build(:page_view, user_agent: 'SomeWeirdBrowser/1.0')
      expect(page_view.browser_name).to eq('Other')
    end

    it 'handles empty string user agent' do
      page_view = build(:page_view, user_agent: '')
      expect(page_view.browser_name).to eq('Unknown')
    end

    it 'prioritizes Chrome detection' do
      page_view = build(:page_view, user_agent: 'Mozilla/5.0 AppleWebKit/537.36 Chrome/120.0 Safari/537.36')
      expect(page_view.browser_name).to eq('Chrome')
    end

    it 'detects Safari when no Chrome' do
      page_view = build(:page_view, user_agent: 'Mozilla/5.0 AppleWebKit/537.36 Safari/537.36')
      expect(page_view.browser_name).to eq('Safari')
    end

    it 'detects Firefox' do
      page_view = build(:page_view, user_agent: 'Mozilla/5.0 Gecko/20100101 Firefox/120.0')
      expect(page_view.browser_name).to eq('Firefox')
    end
  end
end
