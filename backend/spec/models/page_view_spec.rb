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
    before do
      create_list(:page_view, 3, created_at: Date.today)
      create_list(:page_view, 2, created_at: 1.day.ago)
    end
    
    it 'groups views by date' do
      views = PageView.views_by_date(7)
      expect(views[Date.today]).to eq(3)
      expect(views[1.day.ago.to_date]).to eq(2)
    end
  end
  
  describe '.unique_visitors' do
    before do
      create(:page_view, ip_address: '192.168.1.1')
      create(:page_view, ip_address: '192.168.1.1')
      create(:page_view, ip_address: '192.168.1.2')
    end
    
    it 'counts unique IP addresses' do
      expect(PageView.unique_visitors(30)).to eq(2)
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
end
