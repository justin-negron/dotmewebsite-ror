class CreateProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :projects do |t|
      t.string :title, null: false
      t.text :description
      t.text :tech_stack, array: true, default: []
      t.string :github_url
      t.string :live_url
      t.string :image_url
      t.boolean :featured, default: false
      t.integer :display_order

      t.timestamps
    end

    add_index :projects, :featured
    add_index :projects, :display_order
  end
end