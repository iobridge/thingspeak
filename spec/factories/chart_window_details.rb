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

# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :chart_window_detail do
    chart_window_id 1
    field_number 1
  end
end
