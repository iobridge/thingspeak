FactoryGirl.define do
  factory :plugin do
    name "Plugin Name"
    user_id 1
    html = "<html/>"
    css = "<style/>"
    js = "<script/>"
    private_flag = true
    # association :user
  end
end
