class AddWtypeToWindows < ActiveRecord::Migration
  def self.up
    add_column :windows, :wtype, :string
  end

  def self.down
    remove_column :windows, :wtype
  end
end
