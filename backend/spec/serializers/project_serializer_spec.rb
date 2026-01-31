require 'rails_helper'

RSpec.describe ProjectSerializer do
  describe 'serialization' do
    it 'includes all attributes when present' do
      project = create(:project, 
        github_url: 'https://github.com/test',
        live_url: 'https://test.com',
        image_url: 'https://test.com/image.png'
      )
      serializer = ProjectSerializer.new(project)
      serializable = serializer.serializable_hash
      
      expect(serializable[:github_url]).to eq('https://github.com/test')
      expect(serializable[:live_url]).to eq('https://test.com')
      expect(serializable[:image_url]).to eq('https://test.com/image.png')
    end
    
    it 'returns nil for blank github_url' do
      project = create(:project, github_url: nil)
      serializer = ProjectSerializer.new(project)
      serializable = serializer.serializable_hash
      
      expect(serializable[:github_url]).to be_nil
    end
    
    it 'returns nil for empty string github_url' do
      project = create(:project, github_url: '')
      serializer = ProjectSerializer.new(project)
      serializable = serializer.serializable_hash
      
      expect(serializable[:github_url]).to be_nil
    end
    
    it 'returns nil for blank live_url' do
      project = create(:project, live_url: nil)
      serializer = ProjectSerializer.new(project)
      serializable = serializer.serializable_hash
      
      expect(serializable[:live_url]).to be_nil
    end
    
    it 'returns nil for empty string live_url' do
      project = create(:project, live_url: '')
      serializer = ProjectSerializer.new(project)
      serializable = serializer.serializable_hash
      
      expect(serializable[:live_url]).to be_nil
    end
    
    it 'returns nil for blank image_url' do
      project = create(:project, image_url: nil)
      serializer = ProjectSerializer.new(project)
      serializable = serializer.serializable_hash
      
      expect(serializable[:image_url]).to be_nil
    end
    
    it 'returns nil for empty string image_url' do
      project = create(:project, image_url: '')
      serializer = ProjectSerializer.new(project)
      serializable = serializer.serializable_hash
      
      expect(serializable[:image_url]).to be_nil
    end
    
    it 'formats created_at when present' do
      project = create(:project)
      serializer = ProjectSerializer.new(project)
      serializable = serializer.serializable_hash
      
      expect(serializable[:created_at]).to match(/\d{4}-\d{2}-\d{2}T/)
    end
    
    it 'handles nil created_at' do
      project = build(:project, created_at: nil)
      serializer = ProjectSerializer.new(project)
      serializable = serializer.serializable_hash
      
      expect(serializable[:created_at]).to be_nil
    end
    
    it 'formats updated_at when present' do
      project = create(:project)
      serializer = ProjectSerializer.new(project)
      serializable = serializer.serializable_hash
      
      expect(serializable[:updated_at]).to match(/\d{4}-\d{2}-\d{2}T/)
    end
    
    it 'handles nil updated_at' do
      project = build(:project, updated_at: nil)
      serializer = ProjectSerializer.new(project)
      serializable = serializer.serializable_hash
      
      expect(serializable[:updated_at]).to be_nil
    end
  end
end