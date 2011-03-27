require 'spec_helper'

describe ApiKey do
  pending "add some examples to (or delete) #{__FILE__}"
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

