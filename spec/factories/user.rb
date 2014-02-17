FactoryGirl.define do
  factory :user do
    sequence(:login) {|n| "name#{n}" }
    sequence(:email) {|n| "email#{n}@example.com" }
    password "foobar"
    password_confirmation {|u| u.password}
    bio ""
    website ""
    time_zone "London"
    api_key 'ED1HVHNEH2BZD0AB'
  end
end

