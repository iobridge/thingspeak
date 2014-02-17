# == Schema Information
#
# Table name: failedlogins
#
#  id         :integer          not null, primary key
#  login      :string(255)
#  password   :string(255)
#  ip_address :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Failedlogin < ActiveRecord::Base
end
