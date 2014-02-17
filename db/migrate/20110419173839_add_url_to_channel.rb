class AddUrlToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :url, :string
  end

  def self.down
    remove_column :channels, :status
  end
end
