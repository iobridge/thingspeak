class AddApiKeyToTwitters < ActiveRecord::Migration
  def self.up
		add_column :twitters, :api_key, :string, :limit => 16
		add_index :twitters, :api_key
  end

  def self.down
		remove_index :twitters, :api_key
		remove_column :twitters, :api_key
  end
end
