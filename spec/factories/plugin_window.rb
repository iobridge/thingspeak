# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :plugin_window do
    channel_id 1
    position 1
    html "<iframe ::OPTIONS::></iframe>"
    
    col 0
  end
end
