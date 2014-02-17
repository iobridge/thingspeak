# == Schema Information
#
# Table name: tags
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Tag < ActiveRecord::Base
  has_many :taggings
  has_many :channels, :through => :taggings

  validates_presence_of :name

  self.include_root_in_json = false

end
