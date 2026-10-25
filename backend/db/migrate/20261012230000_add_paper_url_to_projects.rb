class AddPaperUrlToProjects < ActiveRecord::Migration[8.1]
  # Optional link to a paper or book chapter about the project. Rendered as a
  # "Publication" link on the project card next to Source and Live.
  def change
    add_column :projects, :paper_url, :string
  end
end
