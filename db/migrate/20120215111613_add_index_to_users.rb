class AddIndexToUsers < ActiveRecord::Migration
  def self.up
    add_index :users, :email
  end

  def self.down
    remove_index :users, :email
  end
end
