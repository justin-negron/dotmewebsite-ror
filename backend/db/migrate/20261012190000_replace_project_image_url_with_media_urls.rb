# Projects carry an ordered list of media URLs (a slideshow) instead of a
# single cover image. Any existing cover becomes the first slide.
#
# image_url stays for now: deploy.sh migrates while the previous release is
# still serving, and that release's ProjectResource reads the column. Project
# ignores the column so this release never names it either, and the column
# gets dropped by a follow-up migration shipped with the NEXT deploy.
class ReplaceProjectImageUrlWithMediaUrls < ActiveRecord::Migration[8.1]
  def up
    add_column :projects, :media_urls, :string, array: true, default: [], null: false

    execute <<~SQL.squish
      UPDATE projects
      SET media_urls = ARRAY[image_url]
      WHERE image_url IS NOT NULL AND image_url <> ''
    SQL
  end

  def down
    remove_column :projects, :media_urls
  end
end
