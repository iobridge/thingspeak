class AddIndexToChannel < ActiveRecord::Migration
  def self.up
     add_index(:channels, :ranking)
  end

  def self.down
  end
end
