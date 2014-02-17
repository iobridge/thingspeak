class AddIndexesToPortlets < ActiveRecord::Migration
  def change
    add_index :windows, :channel_id
    add_index :portlet_window_details, :portlet_window_id
  end
end

