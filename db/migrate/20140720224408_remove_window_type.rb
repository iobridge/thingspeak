class RemoveWindowType < ActiveRecord::Migration
  def change
    remove_column :windows, :type
  end
end

