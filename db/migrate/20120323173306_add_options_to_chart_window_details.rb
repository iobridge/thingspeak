class AddOptionsToChartWindowDetails < ActiveRecord::Migration
  def self.up
    add_column :chart_window_details, :options, :string
  end

  def self.down
    remove_column :chart_window_details, :options
  end
end
