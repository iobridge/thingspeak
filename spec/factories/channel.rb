FactoryGirl.define do
  factory :channel do
    name "Channel name"
    user_id 1
    last_entry_id 1
    video_type "youtube"
    video_id = "123345"
    # association :user
  end
end

