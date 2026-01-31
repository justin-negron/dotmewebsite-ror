require 'rails_helper'

RSpec.describe PageViewSerializer do
  let(:page_view) { create(:page_view, user_agent: 'Mozilla/5.0 Chrome/120.0', path: '/about') }
  let(:serializer) { PageViewSerializer.new(page_view) }
  
  describe 'attributes' do
    it 'includes all required attributes' do
      page_view = create(:page_view)
      serializer = PageViewSerializer.new(page_view)
      serialization = ActiveModelSerializers::Adapter.create(serializer)
      json = JSON.parse(serialization.to_json)
      
      # The response is wrapped in 'page_view' key
      page_view_data = json['page_view']
      
      expect(page_view_data).to have_key('id')
      expect(page_view_data).to have_key('path')
      expect(page_view_data).to have_key('browser_name')
      expect(page_view_data).to have_key('created_at')
    end
  end
  
  describe '#browser_name' do
    it 'returns browser name from model' do
      expect(serializer.browser_name).to eq(page_view.browser_name)
    end
  end
  
  describe '#created_at' do
    it 'formats timestamp as ISO 8601' do
      result = serializer.created_at
      expect(result).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end
    
    it 'handles nil created_at gracefully' do
      pv = PageView.new(path: '/test', created_at: nil)
      ser = PageViewSerializer.new(pv)
      expect(ser.created_at).to be_nil
    end
  end
  
  describe 'privacy' do
    it 'does not expose user_agent' do
      serialization = ActiveModelSerializers::Adapter.create(serializer)
      json = JSON.parse(serialization.to_json)
      expect(json).not_to have_key('user_agent')
    end
    
    it 'does not expose ip_address' do
      serialization = ActiveModelSerializers::Adapter.create(serializer)
      json = JSON.parse(serialization.to_json)
      expect(json).not_to have_key('ip_address')
    end
  end
end