# Columns the models already treat as required but the schema left nullable.
class BackfillAndEnforceNotNullColumns < ActiveRecord::Migration[8.1]
  def up
    change_column_null :contacts, :status, false, "new"
    change_column_null :projects, :description, false, ""
    change_column_null :projects, :featured, false, false
    change_column_null :blog_posts, :published, false, false
    change_column_null :blog_posts, :view_count, false, 0
  end

  def down
    change_column_null :contacts, :status, true
    change_column_null :projects, :description, true
    change_column_null :projects, :featured, true
    change_column_null :blog_posts, :published, true
    change_column_null :blog_posts, :view_count, true
  end
end
