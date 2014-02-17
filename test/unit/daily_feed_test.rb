# == Schema Information
#
# Table name: daily_feeds
#
#  id          :integer          not null, primary key
#  channel_id  :integer
#  date        :date
#  calculation :string(20)
#  result      :string(255)
#  field       :integer
#

require 'test_helper'

class DailyFeedTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
