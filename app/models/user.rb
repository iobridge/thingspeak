# == Schema Information
#
# Table name: users
#
#  id                :integer          not null, primary key
#  login             :string(255)      not null
#  email             :string(255)      not null
#  crypted_password  :string(255)      not null
#  password_salt     :string(255)      not null
#  persistence_token :string(255)      not null
#  perishable_token  :string(255)      not null
#  current_login_at  :datetime
#  last_login_at     :datetime
#  current_login_ip  :string(255)
#  last_login_ip     :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  time_zone         :string(255)
#  public_flag       :boolean          default(FALSE)
#  bio               :text
#  website           :string(255)
#  api_key           :string(16)
#

####### NOTE #######
# user.api_keys is a collection of channel api_keys (read and write)
# user.api_key is a single api_key that allows control of a user's account
####################
class User < ActiveRecord::Base
  include KeyUtilities
  has_many :channels
  has_many :twitter_accounts, :dependent => :destroy
  has_many :thinghttps, :dependent => :destroy
  has_many :tweetcontrols, :dependent => :destroy
  has_many :reacts, :dependent => :destroy
  has_many :scheduled_thinghttps, :dependent => :destroy
  has_many :talkbacks, :dependent => :destroy
  has_many :plugins
  has_many :devices
  has_many :api_keys
  has_many :watchings, :dependent => :destroy
  has_many :watched_channels, :through => :watchings, :source => :channel
  has_many :comments

  acts_as_authentic

  self.include_root_in_json = false

  # pagination variables
  cattr_reader :per_page
  @@per_page = 50

  # find a user using login or email
  def self.find_by_login_or_email(login)
    User.find_by_login(login) || User.find_by_email(login)
  end

  # get user signups per day
  def self.signups_per_day
    sql = 'select DATE_FORMAT(created_at,"%Y-%m-%d") as day, count(id) as signups from users group by day'
    days = ActiveRecord::Base.connection.execute(sql)
    return days
  end

  # for to_json or to_xml, return only the public attributes
  def self.public_options(user)
    output = { :only => [:id, :login, :created_at] }

    # if the profile is public
    if user.public_flag == true
      additional_options = { :only => [:website, :bio] }
      # merge in the additional options by adding the values
      output.merge!(additional_options){ |key, oldval, newval| oldval + newval }
    end

    return output
  end

  # for to_json or to_xml, return the correct private attributes
  def self.private_options
    { :only => [:id, :login, :created_at, :email, :website, :bio] }
  end

  # set new api key
  def set_new_api_key!
    new_api_key = generate_api_key(16, 'user')
    self.update_column(:api_key, new_api_key)
    return new_api_key
  end

end


