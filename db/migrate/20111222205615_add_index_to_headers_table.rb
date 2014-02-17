class AddIndexToHeadersTable < ActiveRecord::Migration
  def self.up
    add_index :headers, :thinghttp_id
  end

  def self.down
    remove_index :headers, :thinghttp_id
  end
end
