class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.integer :parent_id
      t.text :body
      t.integer :flags
      t.integer :user_id
      t.string :ip_address

      t.timestamps
    end
  end

  def self.down
    drop_table :comments
  end
end
