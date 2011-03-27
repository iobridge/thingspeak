class Channel < ActiveRecord::Base
	belongs_to :user
	has_many :feeds
	has_many :api_keys
end






# == Schema Information
#
# Table name: channels
#
#  id            :integer(4)      not null, primary key
#  user_id       :integer(4)
#  name          :string(255)
#  description   :string(255)
#  latitude      :decimal(15, 10)
#  longitude     :decimal(15, 10)
#  field1        :text
#  field2        :text
#  field3        :text
#  field4        :text
#  field5        :text
#  field6        :text
#  field7        :text
#  field8        :text
#  scale1        :integer(4)
#  scale2        :integer(4)
#  scale3        :integer(4)
#  scale4        :integer(4)
#  scale5        :integer(4)
#  scale6        :integer(4)
#  scale7        :integer(4)
#  scale8        :integer(4)
#  created_at    :datetime
#  updated_at    :datetime
#  elevation     :string(255)
#  last_entry_id :integer(4)
#  public_flag   :boolean(1)      default(FALSE)
#

