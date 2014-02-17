class RenameTwittersTable < ActiveRecord::Migration
  def self.up
    rename_table :twitters, :twitter_accounts
  end

  def self.down
    rename_table :twitter_accounts, :twitters
  end
end
