# == Schema Information
#
# Table name: api_keys
#
#  id         :integer          not null, primary key
#  api_key    :string(16)
#  channel_id :integer
#  user_id    :integer
#  write_flag :boolean          default(FALSE)
#  created_at :datetime
#  updated_at :datetime
#  note       :string(255)
#

class ApiKey < ActiveRecord::Base
  belongs_to :channel
  belongs_to :user

  validates_uniqueness_of :api_key

  scope :write_keys, lambda { where("write_flag = true") }
  scope :read_keys, lambda { where("write_flag = false") }

  attr_readonly :created_at

  def to_s
    api_key
  end

  def to_param
    api_key
  end
end




