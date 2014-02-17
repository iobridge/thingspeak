class DocsController < ApplicationController

  def index; ;end

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

