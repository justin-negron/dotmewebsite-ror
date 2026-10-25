require 'rails_helper'

RSpec.describe ProjectResource do
  describe 'serialization' do
    it 'includes all attributes when present' do
      project = create(:project,
        github_url: 'https://github.com/test',
        live_url: 'https://test.com',
        paper_url: 'https://doi.org/10.1000/example',
        media_urls: [ 'https://test.com/one.webp', 'https://test.com/two.webp' ]
      )
      result = ProjectResource.new(project).to_h

      expect(result["github_url"]).to eq('https://github.com/test')
      expect(result["live_url"]).to eq('https://test.com')
      expect(result["paper_url"]).to eq('https://doi.org/10.1000/example')
      expect(result["media_urls"]).to eq([ 'https://test.com/one.webp', 'https://test.com/two.webp' ])
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

    it 'returns nil for blank paper_url' do
      project = create(:project, paper_url: nil)
      result = ProjectResource.new(project).to_h

      expect(result["paper_url"]).to be_nil
    end

    it 'returns nil for empty string paper_url' do
      project = create(:project, paper_url: '')
      result = ProjectResource.new(project).to_h

      expect(result["paper_url"]).to be_nil
    end

    it 'returns an empty array when there are no media_urls' do
      project = create(:project, media_urls: [])
      result = ProjectResource.new(project).to_h

      expect(result["media_urls"]).to eq([])
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
