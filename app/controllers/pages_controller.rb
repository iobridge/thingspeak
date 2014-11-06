class PagesController < ApplicationController
  layout 'application', :except => [:home, :social_home]

  def home
    @menu = 'Internet of Things'
    render layout: 'home'
  end

  def social_home; ; end

  def about
    @menu = 'about'
  end

  def headers
  end

  # post contact email
  def contact_us
    # if no email address
    if params[:email].blank? || params[:email].index('@').blank?
      flash[:alert] = t(:contact_us_no_email)
    # if no message
    elsif params[:message].blank?
      flash[:alert] = t(:contact_us_no_message)
    # else send email if not a spambot (user must have javascript enabled)
    elsif params[:userlogin_js] == '6H2W6QYUAJT1Q8EB'
      Mailer.contact_us(params[:email], params[:message]).deliver
      flash[:notice] = t(:contact_us_success)
    end

    redirect_to root_path
  end

end

