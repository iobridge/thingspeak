FactoryGirl.define do
  factory :plugin do
    name "Plugin Name"
    user_id 1
    html = "<html/>"
    css = "<style/>"
    js = "<script/>"
    public_flag = false
  end
end

