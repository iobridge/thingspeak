class AddIndexToChartWindowDetails < ActiveRecord::Migration
  def change
    add_index :chart_window_details, :chart_window_id
  end
end

