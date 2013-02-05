class ApiKey < ActiveRecord::Base
  belongs_to :channel
  belongs_to :user

  validates_uniqueness_of :api_key

  scope :write_keys, :conditions => { :write_flag => true }
  scope :read_keys, :conditions => { :write_flag => false }

  attr_readonly :created_at
  attr_accessible :note

  def to_s
    api_key
  end

  def to_param
    api_key
  end
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

