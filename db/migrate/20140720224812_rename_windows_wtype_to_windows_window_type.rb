class RenameWindowsWtypeToWindowsWindowType < ActiveRecord::Migration
  def change
    rename_column :windows, :wtype, :window_type
  end
end

