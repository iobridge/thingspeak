class Mailer < ActionMailer::Base
  default :from => 'support@thingspeak.com'

  def password_reset(user, webpage)
    @user = user
    @webpage = webpage
    mail(:to => @user.email,
      :subject => t(:password_reset_subject))
  end

  def contact_us(from_email, message)
    mail(to: SUPPORT_EMAIL,
         from: from_email,
         reply_to: from_email,
         body: message,
         content_type: "text/html",
         subject: "Contact Us Form")
  end

end

