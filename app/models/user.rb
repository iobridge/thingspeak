class User < ActiveRecord::Base
  has_many :channels
  has_many :api_keys

  acts_as_authentic

  def self.find_by_login_or_email(login)
    User.find_by_login(login) || User.find_by_email(login)
  end
end


# == Schema Information
#
# Table name: users
#
#  id                :integer(4)      not null, primary key
#  login             :string(255)     not null
#  email             :string(255)     not null
#  crypted_password  :string(255)     not null
#  password_salt     :string(255)     not null
#  persistence_token :string(255)     not null
#  perishable_token  :string(255)     not null
#  current_login_at  :datetime
#  last_login_at     :datetime
#  current_login_ip  :string(255)
#  last_login_ip     :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  time_zone         :string(255)
#

