class AddIndexesToWindows < ActiveRecord::Migration
  def change
    add_index :windows, [:window_type, :content_id]
  end
end

