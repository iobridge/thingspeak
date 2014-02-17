# == Schema Information
#
# Table name: twitter_accounts
#
#  id          :integer          not null, primary key
#  screen_name :string(255)
#  user_id     :integer
#  twitter_id  :integer
#  token       :string(255)
#  secret      :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  api_key     :string(17)       not null
#

require 'spec_helper'

describe TwitterAccount do

end


