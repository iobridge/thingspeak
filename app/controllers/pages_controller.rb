class PagesController < ApplicationController
  layout 'application', :except => [:social_home]

  def home
    @menu = 'home'
    @title = 'Internet of Things'
  end

  def social_home; ; end

  def features
    @menu = 'features'
  end

  def about
    @menu = 'about'
  end

  def headers
  end

end

