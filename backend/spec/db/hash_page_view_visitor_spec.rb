require 'rails_helper'
require Rails.root.join('db/migrate/20261014000000_hash_page_view_visitor')

RSpec.describe HashPageViewVisitor do
  it 'refuses to roll back because the blanked IP addresses cannot be restored' do
    expect { described_class.new.down }.to raise_error(ActiveRecord::IrreversibleMigration, /cannot be restored/)
  end
end
