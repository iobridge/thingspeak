class AddTypeToWindow < ActiveRecord::Migration
  def self.up
    add_column :windows, :type, :string
  end

  def self.down
    remove_column :windows, :type
  end
end
