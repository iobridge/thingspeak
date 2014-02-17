# == Schema Information
#
# Table name: comments
#
#  id         :integer          not null, primary key
#  parent_id  :integer
#  body       :text
#  flags      :integer
#  user_id    :integer
#  ip_address :string(255)
#  created_at :datetime
#  updated_at :datetime
#  channel_id :integer
#

class Comment < ActiveRecord::Base
  belongs_to :channel
  belongs_to :user
  acts_as_tree :order => 'created_at'

  validates :body, :presence => true
  validates_associated :user

  before_create :set_defaults

  private

  def set_defaults
    self.flags = 0
  end
end

