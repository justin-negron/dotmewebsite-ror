require 'rails_helper'

RSpec.describe ProjectResource do
  describe 'serialization' do
    it 'includes all attributes when present' do
      project = create(:project,
        github_url: 'https://github.com/test',
        live_url: 'https://test.com',
        image_url: 'https://test.com/image.png'
      )
      result = ProjectResource.new(project).to_h

      expect(result["github_url"]).to eq('https://github.com/test')
      expect(result["live_url"]).to eq('https://test.com')
      expect(result["image_url"]).to eq('https://test.com/image.png')
    end

    it 'returns nil for blank github_url' do
      project = create(:project, github_url: nil)
      result = ProjectResource.new(project).to_h

      expect(result["github_url"]).to be_nil
    end

    it 'returns nil for empty string github_url' do
      project = create(:project, github_url: '')
      result = ProjectResource.new(project).to_h

      expect(result["github_url"]).to be_nil
    end

    it 'returns nil for blank live_url' do
      project = create(:project, live_url: nil)
      result = ProjectResource.new(project).to_h

      expect(result["live_url"]).to be_nil
    end

    it 'returns nil for empty string live_url' do
      project = create(:project, live_url: '')
      result = ProjectResource.new(project).to_h

      expect(result["live_url"]).to be_nil
    end

    it 'returns nil for blank image_url' do
      project = create(:project, image_url: nil)
      result = ProjectResource.new(project).to_h

      expect(result["image_url"]).to be_nil
    end

    it 'returns nil for empty string image_url' do
      project = create(:project, image_url: '')
      result = ProjectResource.new(project).to_h

      expect(result["image_url"]).to be_nil
    end

    it 'formats created_at when present' do
      project = create(:project)
      result = ProjectResource.new(project).to_h

      expect(result["created_at"]).to match(/\d{4}-\d{2}-\d{2}T/)
    end

    it 'handles nil created_at' do
      project = build(:project, created_at: nil)
      result = ProjectResource.new(project).to_h

      expect(result["created_at"]).to be_nil
    end

    it 'formats updated_at when present' do
      project = create(:project)
      result = ProjectResource.new(project).to_h

      expect(result["updated_at"]).to match(/\d{4}-\d{2}-\d{2}T/)
    end

    it 'handles nil updated_at' do
      project = build(:project, updated_at: nil)
      result = ProjectResource.new(project).to_h

      expect(result["updated_at"]).to be_nil
    end
  end
end
