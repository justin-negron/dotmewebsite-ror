require 'rails_helper'

RSpec.describe BlogPost, type: :model do
  describe 'validations' do
    subject { build(:blog_post) }
    
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:content) }
    it { should validate_uniqueness_of(:slug) }
    
    it 'validates slug format' do
      blog_post = build(:blog_post, slug: 'Invalid Slug!')
      expect(blog_post).not_to be_valid
      expect(blog_post.errors[:slug]).to be_present
    end
  end
  
  describe 'scopes' do
    let!(:published_post) { create(:blog_post, :published) }
    let!(:draft_post) { create(:blog_post, :draft) }
    
    it 'returns only published posts' do
      expect(BlogPost.published).to include(published_post)
      expect(BlogPost.published).not_to include(draft_post)
    end
    
    it 'returns only drafts' do
      expect(BlogPost.draft).to include(draft_post)
      expect(BlogPost.draft).not_to include(published_post)
    end
  end
  
  describe '#increment_view_count!' do
    it 'increments the view count' do
      post = create(:blog_post, view_count: 5)
      expect { post.increment_view_count! }.to change { post.reload.view_count }.from(5).to(6)
    end
  end
  
  describe '#reading_time' do
    it 'calculates reading time based on word count' do
      post = create(:blog_post, content: 'word ' * 200)
      expect(post.reading_time).to eq(1)
    end
  end
  
  describe 'slug generation' do
    it 'auto-generates slug from title' do
      post = create(:blog_post, title: 'My Great Post', slug: nil)
      expect(post.slug).to eq('my-great-post')
    end
  end

  describe 'slug generation with counters' do
    it 'finds next available slug number when multiple exist' do
      # Create posts occupying slots 0, 1, 2
      BlogPost.create!(title: 'Post', content: 'Content', slug: 'post')
      BlogPost.create!(title: 'Post', content: 'Content', slug: 'post-1')
      BlogPost.create!(title: 'Post', content: 'Content', slug: 'post-2')
      
      # Next one should be post-3
      new_post = BlogPost.create!(title: 'Post', content: 'Content')
      expect(new_post.slug).to eq('post-3')
    end
    
    it 'loops through counter until finding available slug' do
      # Create posts with gaps
      BlogPost.create!(title: 'Test', content: 'Content', slug: 'test')
      BlogPost.create!(title: 'Test', content: 'Content', slug: 'test-1')
      BlogPost.create!(title: 'Test', content: 'Content', slug: 'test-2')
      
      # Should assign test-3
      post = BlogPost.create!(title: 'Test', content: 'Content')
      expect(post.slug).to eq('test-3')
    end
  end

  describe 'callback behavior' do
    it 'uses existing slug when provided' do
      post = BlogPost.create!(title: 'Title', slug: 'custom-slug', content: 'Content')
      expect(post.slug).to eq('custom-slug')
    end
    
    it 'generates slug when not provided' do
      post = BlogPost.create!(title: 'My Title', content: 'Content')
      expect(post.slug).to eq('my-title')
    end
    
    it 'keeps existing excerpt when provided' do
      post = BlogPost.create!(title: 'Title', slug: 'slug', content: 'Long content here', excerpt: 'Custom excerpt')
      expect(post.excerpt).to eq('Custom excerpt')
    end
  end

  describe 'slug generation with collisions' do
    it 'appends -1 when slug already exists' do
      BlogPost.create!(title: 'Great Post', content: 'Content', slug: 'great-post')
      second = BlogPost.create!(title: 'Great Post', content: 'Content')
      
      expect(second.slug).to eq('great-post-1')
    end
    
    it 'increments counter when multiple slugs exist' do
      BlogPost.create!(title: 'Post', content: 'Content', slug: 'post')
      BlogPost.create!(title: 'Post', content: 'Content')  # gets post-1
      third = BlogPost.create!(title: 'Post', content: 'Content')
      
      expect(third.slug).to eq('post-2')
    end
  end

  describe '#reading_time with long content' do
    it 'calculates for very long posts' do
      long_content = 'word ' * 1000
      post = create(:blog_post, content: long_content)
      
      expect(post.reading_time).to eq(5) # 1000 words / 200 wpm
    end
  end

  describe 'excerpt generation' do
    it 'uses provided excerpt if present' do
      post = create(:blog_post, excerpt: 'Custom excerpt', content: 'Long content')
      expect(post.excerpt).to eq('Custom excerpt')
    end
  end

  describe 'slug generation edge cases' do
    it 'handles multiple duplicate slugs' do
      # Create first post with specific slug
      first = BlogPost.create!(title: 'Great Post', content: 'Content', slug: 'great-post')
      
      # Create second post with same title - should get great-post-1
      second = BlogPost.create!(title: 'Great Post', content: 'Content')
      expect(second.slug).to eq('great-post-1')
      
      # Create third post with same title - should get great-post-2
      third = BlogPost.create!(title: 'Great Post', content: 'Content')
      expect(third.slug).to eq('great-post-2')
    end
    
    it 'does not generate slug when title is blank' do
      post = BlogPost.new(title: nil, content: 'Content', slug: nil)
      post.valid?
      
      expect(post.slug).to be_nil
    end
    
    it 'does not regenerate slug if already present' do
      post = BlogPost.new(title: 'New Title', slug: 'custom-slug', content: 'Content')
      post.save
      
      expect(post.slug).to eq('custom-slug')
    end
  end

  describe 'excerpt generation edge cases' do
    it 'does not generate excerpt when content is blank' do
      post = BlogPost.new(title: 'Title', slug: 'slug', content: nil)
      post.valid?
      
      expect(post.excerpt).to be_nil
    end
    
    it 'does not override existing excerpt' do
      post = create(:blog_post, excerpt: 'Custom excerpt', content: 'Long content here')
      
      expect(post.excerpt).to eq('Custom excerpt')
    end
    
    it 'truncates long content for excerpt' do
      long_content = 'word ' * 100
      post = create(:blog_post, content: long_content, excerpt: nil)
      
      expect(post.excerpt.length).to be <= 163
      expect(post.excerpt).to end_with('...')
    end
  end

  describe 'publishing' do
    it 'sets published_at when publishing' do
      post = create(:blog_post, :draft)
      
      expect {
        post.update(published: true)
      }.to change { post.published_at }.from(nil)
    end
    
    it 'does not change published_at when already published' do
      post = create(:blog_post, :published)
      original_time = post.published_at
      
      post.update(title: 'New Title')
      
      expect(post.published_at).to eq(original_time)
    end
    
    it 'does not set published_at when unpublishing' do
      post = create(:blog_post, :published)
      
      post.update(published: false)
      
      expect(post.published_at).to be_present
    end
  end

  describe 'slug counter loop' do
    it 'keeps incrementing until finding available slug' do
      # Create slugs: post, post-1, post-2
      BlogPost.create!(title: 'Post', content: 'C', slug: 'post')
      BlogPost.create!(title: 'Post', content: 'C', slug: 'post-1')
      BlogPost.create!(title: 'Post', content: 'C', slug: 'post-2')
      
      # This should loop through counter 1, 2, 3 and assign post-3
      new_post = BlogPost.create!(title: 'Post', content: 'C')
      expect(new_post.slug).to eq('post-3')
    end
  end

  describe 'slug generation break condition' do
    it 'exits loop when finding available slug' do
      BlogPost.create!(title: 'Test', content: 'Content', slug: 'test')
      # Creating with same title should check 'test-1', find it available, and break
      new_post = BlogPost.create!(title: 'Test', content: 'Content')
      expect(new_post.slug).to eq('test-1')
    end
  end

  describe 'set_published_at callback' do
    it 'sets published_at when changing published to true' do
      post = create(:blog_post, :draft, published_at: nil)
      post.update(published: true)
      expect(post.published_at).to be_present
    end
    
    it 'does not set published_at when published changes to false' do
      post = create(:blog_post, :published)
      original_time = post.published_at
      
      post.update(published: false)
      
      # Callback fires (published_changed? is true) but skips the if body (published? is false)
      expect(post.published_at).to eq(original_time)
    end
  end

  describe '#tags_list' do
    it 'returns comma-separated tags' do
      post = create(:blog_post, tags: ['ruby', 'rails', 'testing'])
      expect(post.tags_list).to eq('ruby, rails, testing')
    end
    
    it 'returns empty string when no tags' do
      post = create(:blog_post, tags: [])
      expect(post.tags_list).to eq('')
    end
  end
end
