class AddIndexesToApiKey < ActiveRecord::Migration
  def self.up
		add_index :api_keys, :api_key, :unique => true
		add_index :api_keys, :device_id
  end

  def self.down
		remove_index :api_keys, :device_id
		remove_index :api_keys, :api_key
  end
end
