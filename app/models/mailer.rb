class Mailer < ActionMailer::Base
	#default :from => 'support@thingspeak.com'

  def password_reset(user, webpage)
		@user = user
		@webpage = webpage
		mail(:to => @user.email,
			:subject => t(:password_reset_subject))
	end

end
