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

class TwitterAccount < ActiveRecord::Base
  include KeyUtilities

  belongs_to :user
  has_many :reacts, :as => :actionable, :dependent => :restrict_with_exception

  # pagination variables
  cattr_reader :per_page
  @@per_page = 50

  before_create :set_api_key

  def renew_api_key
    self.update_attribute(:api_key, generate_api_key(16, 'twitter'))
  end

  def tweet(status, opts = {})
    opts.delete('api_key')
    opts.delete('controller')
    opts.delete('action')

    client = TwitterOAuth::Client.new(
      :consumer_key => CONSUMER_KEY,
      :consumer_secret => CONSUMER_SECRET,
      :token => self.token,
      :secret => self.secret
    )

    client.update(status, opts)

  rescue Twitter::Error::Unauthorized

  end

  private

    def set_api_key
      self.api_key = generate_api_key(16, 'twitter')
    end
end


