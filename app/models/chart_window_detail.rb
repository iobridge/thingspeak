# == Schema Information
#
# Table name: chart_window_details
#
#  id              :integer          not null, primary key
#  chart_window_id :integer
#  field_number    :integer
#  created_at      :datetime
#  updated_at      :datetime
#  options         :string(255)
#

class ChartWindowDetail < ActiveRecord::Base
end
