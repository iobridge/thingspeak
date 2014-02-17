class AddFieldsToPipes < ActiveRecord::Migration
  def self.up
    add_column :pipes, :parse, :string
    add_column :pipes, :cache, :integer
  end

  def self.down
    remove_column :pipes, :parse
    remove_column :pipes, :cache
  end
end
