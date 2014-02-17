class AppsController < ApplicationController

  def index
    @menu = 'apps'
    @title = 'Internet of Things Apps' if current_user.nil?
    # @twitters = TwitterAccount.find(:all, :conditions => { :user_id => current_user.id }) if current_user
  end

end
