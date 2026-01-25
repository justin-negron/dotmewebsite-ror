class CreatePageViews < ActiveRecord::Migration[7.1]
  def change
    create_table :page_views do |t|
      t.string :path, null: false
      t.text :user_agent
      t.inet :ip_address
      t.string :referrer

      t.timestamps
    end

    add_index :page_views, :path
    add_index :page_views, :created_at
    add_index :page_views, :ip_address
  end
end