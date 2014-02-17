class MailerController < ApplicationController

  def resetpassword
    # protect against bots
    render :text => '' and return if params[:userlogin].length > 0

    @user = User.find_by_login_or_email(params[:user][:login])
    if @user.nil?
      sleep 2
      session[:mail_message] = t(:account_not_found)
    else
      begin
        @user.reset_perishable_token!
        Mailer.password_reset(@user, "#{RESET_PASSWORD_URL}#{@user.id}?token=#{@user.perishable_token}").deliver
        session[:mail_message] = t(:password_reset_mailed)
      rescue
        session[:mail_message] = t(:password_reset_error)
      end
    end
    redirect_to login_path
  end

end
