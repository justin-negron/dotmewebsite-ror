class CreateExperiences < ActiveRecord::Migration[7.1]
  def change
    create_table :experiences do |t|
      t.string :company, null: false
      t.string :position, null: false
      t.date :start_date, null: false
      t.date :end_date
      t.text :description
      t.text :technologies, array: true, default: []
      t.integer :display_order

      t.timestamps
    end

    add_index :experiences, :start_date
    add_index :experiences, :display_order
  end
end