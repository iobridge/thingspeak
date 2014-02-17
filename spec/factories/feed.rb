FactoryGirl.define do
  factory :feed do
    field1 "foo"
    field2 "10"
    entry_id 1
    latitude "51.477222"
    longitude "0.0"
    created_at (Time.now - 20.minutes)
    updated_at (Time.now - 20.minutes)
    sequence(:status) {|n| "foo#{n}" }
  end
end
