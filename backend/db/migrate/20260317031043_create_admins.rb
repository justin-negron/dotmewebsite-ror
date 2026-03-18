class CreateAdmins < ActiveRecord::Migration[7.1]
  def change
    create_table :admins do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :refresh_token_jti
      t.datetime :refresh_token_exp

      t.timestamps
    end

    add_index :admins, :email, unique: true
  end
end
