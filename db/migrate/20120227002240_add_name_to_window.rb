class AddNameToWindow < ActiveRecord::Migration
  def self.up
    add_column :windows, :name, :string
  end

  def self.down
    remove_column :windows, :name
  end
end
