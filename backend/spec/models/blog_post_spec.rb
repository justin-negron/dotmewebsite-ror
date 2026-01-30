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
end
