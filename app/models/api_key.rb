class ApiKey < ActiveRecord::Base
	belongs_to :channel

	validates_uniqueness_of :api_key
end





# == Schema Information
#
# Table name: api_keys
#
#  id         :integer(4)      not null, primary key
#  api_key    :string(16)
#  channel_id :integer(4)
#  user_id    :integer(4)
#  write_flag :boolean(1)      default(FALSE)
#  created_at :datetime
#  updated_at :datetime
#  note       :string(255)
#

