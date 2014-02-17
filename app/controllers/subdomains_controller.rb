class SubdomainsController < ApplicationController

  # show a blank page if subdomain
  def index
    render :text => ''
  end

  # output the file crossdomain.xml.erb
  def crossdomain
    respond_to do |format|
      format.xml
    end
  end

end
