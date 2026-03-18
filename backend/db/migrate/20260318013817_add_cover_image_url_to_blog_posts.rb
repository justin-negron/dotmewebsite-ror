class AddCoverImageUrlToBlogPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :blog_posts, :cover_image_url, :string
  end
end
