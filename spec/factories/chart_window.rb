# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :chart_window do
    channel_id 1
    position 1
    html "<iframe src=\"/\"/>"
    col 0
  end
end
