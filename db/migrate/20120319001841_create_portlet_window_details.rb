class CreatePortletWindowDetails < ActiveRecord::Migration
  def self.up
    create_table :portlet_window_details do |t|
      t.integer :portlet_window_id

      t.timestamps
    end
  end

  def self.down
    drop_table :portlet_window_details
  end
end
