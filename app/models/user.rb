# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  login                  :string(255)      not null
#  email                  :string(255)      not null
#  encrypted_password     :string(255)      not null
#  password_salt          :string(255)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  time_zone              :string(255)
#  public_flag            :boolean          default(FALSE)
#  bio                    :text
#  website                :string(255)
#  api_key                :string(16)
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  authentication_token   :string(255)
#  terms_agreed_at        :datetime
#

####### NOTE #######
# user.api_keys is a collection of channel api_keys (read and write)
# user.api_key is a single api_key that allows control of a user's account
####################
class User < ActiveRecord::Base
  include KeyUtilities
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable
  has_many :channels, :dependent => :destroy
  has_many :twitter_accounts, :dependent => :destroy
  has_many :thinghttps, :dependent => :destroy
  has_many :tweetcontrols, :dependent => :destroy
  has_many :reacts, :dependent => :destroy
  has_many :talkbacks, :dependent => :destroy
  has_many :timecontrols, :dependent => :destroy
  has_many :plugins, :dependent => :destroy
  has_many :devices, :dependent => :destroy
  has_many :api_keys, :dependent => :destroy
  has_many :watchings, :dependent => :destroy
  has_many :watched_channels, :through => :watchings, :source => :channel, :dependent => :destroy
  has_many :comments, :dependent => :destroy

  self.include_root_in_json = false

  validates :login, uniqueness: { case_sensitive: false }
  validates :email, uniqueness: { case_sensitive: false }

  # pagination variables
  cattr_reader :per_page
  @@per_page = 50

  # display the user's website correctly
  def display_website
    output = self.website
    output = "http://#{website}" if output.present? && output.index('http') != 0
    return output
  end

  # get the user's time zone or UTC time
  def time_zone_or_utc; time_zone || 'UTC'; end

  # true if the user has used the maximum number of available timecontrols
  def max_timecontrols?
    self.timecontrols.roots.count >= Timecontrol::MAX_PER_USER
  end

  # allow login by login name also
  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login_param = conditions.delete(:login)
      where(conditions).where(["lower(login) = :value OR lower(email) = :value", { :value => login_param.downcase }]).first
    else
      where(conditions).first
    end
  end

  # allow users to sign in with passwords from old authlogic authentication
  alias :devise_valid_password? :valid_password?
  def valid_password?(password)
    begin
      devise_valid_password?(password)
    rescue BCrypt::Errors::InvalidHash
      stretches = 20
      digest  = "#{password}#{self.password_salt}"
      stretches.times {digest = Digest::SHA512.hexdigest(digest)}
      if digest == self.encrypted_password
        #Here update old Authlogic SHA512 Password with new Devise ByCrypt password
        # SOURCE: https://github.com/plataformatec/devise/blob/master/lib/devise/models/database_authenticatable.rb
        # Digests the password using bcrypt.
        self.encrypted_password = self.password_digest(password)
        self.save
        return true
      else
        # If not BCryt password and not old Authlogic SHA512 password don't authenticate user
        return false
      end
    end
  end

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

  # add an extra attribute to private_options
  def self.private_options_plus(array)
    { :only => User.private_options[:only].push(array).flatten }
  end


  # set new api key
  def set_new_api_key!
    new_api_key = generate_api_key(16, 'user')
    self.update_column(:api_key, new_api_key)
    return new_api_key
  end

end

