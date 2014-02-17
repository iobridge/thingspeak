# == Schema Information
#
# Table name: portlet_window_details
#
#  id                :integer          not null, primary key
#  portlet_window_id :integer
#  created_at        :datetime
#  updated_at        :datetime
#

# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :portlet_window_detail do
    portlet_window_id 1
  end
end
