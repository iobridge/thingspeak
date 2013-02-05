class MailerController < ApplicationController

	def resetpassword
		@user = User.find_by_login_or_email(params[:user][:login])

		if @user.nil?
			session[:mail_message] = t(:account_not_found)
		else
			begin
				@user.reset_perishable_token!
				# Mailer.password_reset(@user, "https://www.thingspeak.com/users/#{@user.id}/reset_password?token=#{@user.perishable_token}").deliver
				session[:mail_message] = t(:password_reset_mailed)
			rescue
				session[:mail_message] = t(:password_reset_error)
			end
		end
		redirect_to login_path
	end

end
