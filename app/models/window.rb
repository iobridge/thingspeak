# == Schema Information
#
# Table name: windows
#
#  id           :integer          not null, primary key
#  channel_id   :integer
#  position     :integer
#  created_at   :datetime
#  updated_at   :datetime
#  html         :text
#  col          :integer
#  title        :string(255)
#  window_type  :string(255)
#  name         :string(255)
#  private_flag :boolean          default(FALSE)
#  show_flag    :boolean          default(TRUE)
#  content_id   :integer
#  options      :text
#

# content_id refers to plugin_id, field_number, etc depending on the window type
# valid values for window_type: status, location, chart, plugin, video
class Window < ActiveRecord::Base
  belongs_to :channel

  self.include_root_in_json = true

  def private?
    return private_flag
  end

  def self.new_from( plugin, channel_id, privacy_flag, api_domain )
    window = Window.new
    window.window_type = 'plugin'
    window.position = 0
    window.col = 0
    window.title = "window_plugin"
    window.name = plugin.name
    window.private_flag = (privacy_flag == :private)
    window.channel = Channel.find(channel_id)
    window.html ="<iframe width=\"450\" height=\"260\" style=\"border: 1px solid #cccccc;\" src=\"/plugins/#{plugin.id}\" ></iframe>"
    window.show_flag = false
    window if window.save
  end

  # set the title for display to user; don't save after calling this method
  def set_title_for_display!
    # if this is a plugin
    if window_type == "plugin"
      plugin_name = Plugin.find(content_id).name
      self.title = I18n.t(title, {:name => plugin_name})
    # else if this is a chart
    elsif window_type == "chart"
      self.title = I18n.t(title, {:field_number => content_id})
    # else set title for other window types, for example: I18n.t('window_map') = 'Channel Location'
    else
      self.title = I18n.t(title)
    end
  end

  # set the html for display to user; don't save after calling this method
  def set_html_for_display!
    if window_type == "chart"
      html_options = options || ''
      # replace '::OPTIONS::' if present
      self.html['::OPTIONS::'] = html_options if html.present? && html.index("::OPTIONS::").present?
    end
  end

end

