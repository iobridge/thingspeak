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

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :plugin_window_detail do
    plugin_id 1
    plugin_window_id 1
  end
end
