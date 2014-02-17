class CreateApiKeys < ActiveRecord::Migration
  def self.up
    create_table :api_keys do |t|
      t.string :api_key, :limit => 16
      t.integer :device_id
      t.integer :feed_id
      t.integer :user_id
      t.boolean :write_flag, :default => 0
      t.boolean :public_flag, :default => 0

      t.timestamps
    end
  end

  def self.down
    drop_table :api_keys
  end
end
