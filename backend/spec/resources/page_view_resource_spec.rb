require 'rails_helper'

RSpec.describe PageViewResource do
  describe 'serialization' do
    it 'includes all required attributes' do
      page_view = create(:page_view)
      result = PageViewResource.new(page_view).to_h

      expect(result).to have_key("id")
      expect(result).to have_key("path")
      expect(result).to have_key("browser_name")
      expect(result).to have_key("created_at")
    end

    it 'returns browser name from model' do
      page_view = create(:page_view, user_agent: 'Mozilla/5.0 Chrome/120.0', path: '/about')
      result = PageViewResource.new(page_view).to_h

      expect(result["browser_name"]).to eq(page_view.browser_name)
    end

    it 'formats timestamp as ISO 8601' do
      page_view = create(:page_view)
      result = PageViewResource.new(page_view).to_h

      expect(result["created_at"]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end

    it 'handles nil created_at gracefully' do
      page_view = PageView.new(path: '/test', created_at: nil)
      result = PageViewResource.new(page_view).to_h

      expect(result["created_at"]).to be_nil
    end

    it 'does not expose user_agent' do
      page_view = create(:page_view, user_agent: 'Mozilla/5.0 Chrome/120.0')
      result = PageViewResource.new(page_view).to_h

      expect(result).not_to have_key("user_agent")
    end

    it 'does not expose ip_address' do
      page_view = create(:page_view, ip_address: '127.0.0.1')
      result = PageViewResource.new(page_view).to_h

      expect(result).not_to have_key("ip_address")
    end
  end
end
