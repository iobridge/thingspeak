class CorsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  # dummy method that responds with status 200 for CORS preflighting
  def preflight; render :nothing => true; end

end

