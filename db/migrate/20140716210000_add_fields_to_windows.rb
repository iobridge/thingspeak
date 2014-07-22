class AddFieldsToWindows < ActiveRecord::Migration
  def change
    add_column :windows, :content_id, :integer
    add_column :windows, :options, :text
  end
end

