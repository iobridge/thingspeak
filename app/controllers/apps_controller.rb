class AppsController < ApplicationController

  def index
    @menu = 'apps'
    @title = 'Internet of Things Apps' if current_user.nil?
  end

end

