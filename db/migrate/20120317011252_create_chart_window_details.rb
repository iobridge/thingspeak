class CreateChartWindowDetails < ActiveRecord::Migration
  def self.up
    create_table :chart_window_details do |t|
      t.integer :chart_window_id
      t.integer :field_number

      t.timestamps
    end
  end

  def self.down
    drop_table :chart_window_details
  end
end
