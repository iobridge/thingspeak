class AddColToWindows < ActiveRecord::Migration
  def self.up
    add_column :windows, :col, :integer
    add_column :windows, :title, :string
  end

  def self.down
    remove_column :windows, :title
    remove_column :windows, :col
  end
end
