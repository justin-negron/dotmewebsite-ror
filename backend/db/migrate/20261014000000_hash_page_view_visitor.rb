require "openssl"

# ip_address is blanked, not dropped: deploy.sh migrates while the previous
# release is still serving, and that release writes the column. The column and
# its index get dropped by a follow-up migration shipped with the NEXT deploy.
#
# The derivation matches PageView.visitor_hash_for and is inlined because a
# migration must not lean on model code that can change later. Production
# holds a few hundred rows, so one UPDATE per distinct (day, address) pair is
# the whole backfill. Not reversible: the addresses are gone once blanked.
class HashPageViewVisitor < ActiveRecord::Migration[8.1]
  def up
    add_column :page_views, :visitor_hash, :string, limit: 32
    add_index :page_views, :visitor_hash

    key = Rails.application.key_generator.generate_key("page_view.visitor_hash")
    pairs = select_rows("SELECT DISTINCT created_at::date, host(ip_address) FROM page_views WHERE ip_address IS NOT NULL")
    pairs.each do |day, ip|
      hash = OpenSSL::HMAC.hexdigest("SHA256", key, "#{day}#{ip}")[0, 32]
      execute(<<~SQL.squish)
        UPDATE page_views SET visitor_hash = #{quote(hash)}
        WHERE created_at::date = #{quote(day.to_s)} AND ip_address = #{quote(ip)}
      SQL
    end

    execute("UPDATE page_views SET ip_address = NULL")
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "ip_address was blanked in up and cannot be restored; restore page_views from a backup instead"
  end
end
