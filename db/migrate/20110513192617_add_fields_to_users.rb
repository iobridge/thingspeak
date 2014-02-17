class AddFieldsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :public_flag, :boolean, :default => false
    add_column :users, :bio, :text
    add_column :users, :website, :string
  end

  def self.down
    remove_column :users, :website
    remove_column :users, :bio
    remove_column :users, :public_flag
  end
end
