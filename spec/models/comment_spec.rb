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

require 'spec_helper'

describe Comment do

end

