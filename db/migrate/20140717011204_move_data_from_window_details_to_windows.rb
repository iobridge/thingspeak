class MoveDataFromWindowDetailsToWindows < ActiveRecord::Migration
  def change
    execute "UPDATE windows w, plugin_window_details p SET w.content_id = p.plugin_id WHERE w.id = p.plugin_window_id;"
    execute "UPDATE windows w, chart_window_details c SET w.content_id = c.field_number, w.options = c.options WHERE w.id = c.chart_window_id;"
  end
end

