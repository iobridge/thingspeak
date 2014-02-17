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

require 'spec_helper'

describe ApiKey do

end




