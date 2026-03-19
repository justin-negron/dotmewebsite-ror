class AddExperienceTypeToExperiences < ActiveRecord::Migration[7.1]
  def change
    add_column :experiences, :experience_type, :string, default: 'work', null: false
    add_index :experiences, :experience_type
  end
end
