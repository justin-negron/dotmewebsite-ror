class CreateBlogPosts < ActiveRecord::Migration[7.1]
  def change
    create_table :blog_posts do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :content, null: false
      t.text :excerpt
      t.boolean :published, default: false
      t.datetime :published_at
      t.text :tags, array: true, default: []
      t.integer :view_count, default: 0

      t.timestamps
    end

    add_index :blog_posts, :slug, unique: true
    add_index :blog_posts, [:published, :published_at]
    add_index :blog_posts, :tags, using: :gin
  end
end