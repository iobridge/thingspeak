# == Schema Information
#
# Table name: plugin_window_details
#
#  id               :integer          not null, primary key
#  plugin_id        :integer
#  plugin_window_id :integer
#  created_at       :datetime
#  updated_at       :datetime
#

class PluginWindowDetail < ActiveRecord::Base
  belongs_to :plugin_window
  belongs_to :plugin

end
