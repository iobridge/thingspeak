# == Schema Information
#
# Table name: windows
#
#  id           :integer          not null, primary key
#  channel_id   :integer
#  position     :integer
#  created_at   :datetime
#  updated_at   :datetime
#  html         :text
#  col          :integer
#  title        :string(255)
#  wtype        :string(255)
#  name         :string(255)
#  type         :string(255)
#  private_flag :boolean          default(FALSE)
#  show_flag    :boolean          default(TRUE)
#

# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :window do
    channel_id 1
    position 1
    html "<iframe ::OPTIONS::></iframe>"
    col 0
  end
end
