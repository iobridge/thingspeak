class SessionsController < Devise::SessionsController
  before_filter :fix_params, :only => :create

  # don't modify default devise controllers
  def create; super; end
  def new; super; end

  private

    # fixes password reset params so that devise config.reset_password_keys can be set to email for activeadmin
    def fix_params
      params[:user][:login] = params[:user][:email]
    end

end

