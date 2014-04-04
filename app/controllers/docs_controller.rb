class DocsController < ApplicationController
  before_filter :set_support_menu

  def index; ;  end
  def errors; ; end
  def tweetcontrol; ; end
  def plugins; ; end
  def importer; ; end
  def charts; ; end
  def users; ; end
  def tutorials; ; end

  def channels
    # default values
    @channel_api_key = 'XXXXXXXXXXXXXXXX'
    @user_api_key = 'XXXXXXXXXXXXXXXX'

    # if user is signed in
    if current_user && current_user.channels.any?
      @channel_api_key = current_user.channels.order('updated_at desc').first.write_api_key
      @user_api_key = current_user.api_key
    end
  end

  def thinghttp
    # default values
    @thinghttp_api_key = 'XXXXXXXXXXXXXXXX'

    # if user is signed in
    if current_user && current_user.thinghttps.any?
      @thinghttp_api_key = current_user.thinghttps.order('updated_at desc').first.api_key
    end
  end

  def thingtweet
    # default values
    @thingtweet_api_key = 'XXXXXXXXXXXXXXXX'

    # if user is signed in
    if current_user && current_user.twitter_accounts.any?
      @thingtweet_api_key = current_user.twitter_accounts.order('updated_at desc').first.api_key
    end
  end

  def talkback
    # default values
    @talkback_id = 3
    @talkback_api_key = 'XXXXXXXXXXXXXXXX'

    # if user is signed in
    if current_user && current_user.talkbacks.any?
      @talkback = current_user.talkbacks.order('updated_at desc').first
      @talkback_id = @talkback.id
      @talkback_api_key = @talkback.api_key
    end
  end

end

