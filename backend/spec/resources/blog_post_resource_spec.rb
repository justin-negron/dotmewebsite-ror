require 'rails_helper'

RSpec.describe BlogPostResource do
  describe 'serialization' do
    it 'uses existing excerpt when present' do
      blog_post = create(:blog_post, excerpt: 'Custom excerpt', content: 'Long content')
      result = BlogPostResource.new(blog_post).to_h

      expect(result["excerpt"]).to eq('Custom excerpt')
    end

    it 'generates excerpt from content when excerpt is nil' do
      blog_post = create(:blog_post, excerpt: nil, content: 'This is test content ' * 20)
      result = BlogPostResource.new(blog_post).to_h

      expect(result["excerpt"]).to be_present
      expect(result["excerpt"].length).to be <= 163
    end

    it 'generates excerpt from content when excerpt is empty string' do
      long_content = 'This is test content that is long enough to be truncated properly for the excerpt generation'
      blog_post = create(:blog_post, excerpt: '', content: long_content)
      result = BlogPostResource.new(blog_post).to_h

      expect(result["excerpt"]).to be_present
      expect(result["excerpt"]).not_to eq('')
    end

    it 'handles blank content when generating excerpt' do
      blog_post = build(:blog_post, excerpt: nil, content: '')
      result = BlogPostResource.new(blog_post).to_h

      expect(result["excerpt"]).to eq('')
    end

    it 'formats published_at when present' do
      blog_post = create(:blog_post, :published)
      result = BlogPostResource.new(blog_post).to_h

      expect(result["published_at"]).to match(/\d{4}-\d{2}-\d{2}T/)
    end

    it 'handles nil published_at' do
      blog_post = create(:blog_post, :draft, published_at: nil)
      result = BlogPostResource.new(blog_post).to_h

      expect(result["published_at"]).to be_nil
    end

    it 'formats created_at when present' do
      blog_post = create(:blog_post)
      result = BlogPostResource.new(blog_post).to_h

      expect(result["created_at"]).to match(/\d{4}-\d{2}-\d{2}T/)
    end

    it 'handles nil created_at' do
      blog_post = build(:blog_post, created_at: nil)
      result = BlogPostResource.new(blog_post).to_h

      expect(result["created_at"]).to be_nil
    end

    it 'formats updated_at when present' do
      blog_post = create(:blog_post)
      result = BlogPostResource.new(blog_post).to_h

      expect(result["updated_at"]).to match(/\d{4}-\d{2}-\d{2}T/)
    end

    it 'handles nil updated_at' do
      blog_post = build(:blog_post, updated_at: nil)
      result = BlogPostResource.new(blog_post).to_h

      expect(result["updated_at"]).to be_nil
    end
  end
end
