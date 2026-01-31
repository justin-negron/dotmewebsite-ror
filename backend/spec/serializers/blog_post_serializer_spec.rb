require 'rails_helper'

RSpec.describe BlogPostSerializer do
  describe 'serialization' do
    it 'uses existing excerpt when present' do
      blog_post = create(:blog_post, excerpt: 'Custom excerpt', content: 'Long content')
      serializer = BlogPostSerializer.new(blog_post)
      serializable = serializer.serializable_hash
      
      expect(serializable[:excerpt]).to eq('Custom excerpt')
    end
    
    it 'generates excerpt from content when excerpt is nil' do
      blog_post = create(:blog_post, excerpt: nil, content: 'This is test content ' * 20)
      serializer = BlogPostSerializer.new(blog_post)
      serializable = serializer.serializable_hash
      
      expect(serializable[:excerpt]).to be_present
      expect(serializable[:excerpt].length).to be <= 163
    end
    
    it 'generates excerpt from content when excerpt is empty string' do
      long_content = 'This is test content that is long enough to be truncated properly for the excerpt generation'
      blog_post = create(:blog_post, excerpt: '', content: long_content)
      serializer = BlogPostSerializer.new(blog_post)
      serializable = serializer.serializable_hash
      
      expect(serializable[:excerpt]).to be_present
      expect(serializable[:excerpt]).not_to eq('')
    end
    
    it 'handles blank content when generating excerpt' do
      blog_post = build(:blog_post, excerpt: nil, content: '')
      serializer = BlogPostSerializer.new(blog_post)
      serializable = serializer.serializable_hash
      
      expect(serializable[:excerpt]).to eq('')
    end
    
    it 'formats published_at when present' do
      blog_post = create(:blog_post, :published)
      serializer = BlogPostSerializer.new(blog_post)
      serializable = serializer.serializable_hash
      
      expect(serializable[:published_at]).to match(/\d{4}-\d{2}-\d{2}T/)
    end
    
    it 'handles nil published_at' do
      blog_post = create(:blog_post, :draft, published_at: nil)
      serializer = BlogPostSerializer.new(blog_post)
      serializable = serializer.serializable_hash
      
      expect(serializable[:published_at]).to be_nil
    end
    
    it 'formats created_at when present' do
      blog_post = create(:blog_post)
      serializer = BlogPostSerializer.new(blog_post)
      serializable = serializer.serializable_hash
      
      expect(serializable[:created_at]).to match(/\d{4}-\d{2}-\d{2}T/)
    end
    
    it 'handles nil created_at' do
      blog_post = build(:blog_post, created_at: nil)
      serializer = BlogPostSerializer.new(blog_post)
      serializable = serializer.serializable_hash
      
      expect(serializable[:created_at]).to be_nil
    end
    
    it 'formats updated_at when present' do
      blog_post = create(:blog_post)
      serializer = BlogPostSerializer.new(blog_post)
      serializable = serializer.serializable_hash
      
      expect(serializable[:updated_at]).to match(/\d{4}-\d{2}-\d{2}T/)
    end
    
    it 'handles nil updated_at' do
      blog_post = build(:blog_post, updated_at: nil)
      serializer = BlogPostSerializer.new(blog_post)
      serializable = serializer.serializable_hash
      
      expect(serializable[:updated_at]).to be_nil
    end
  end
end