class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy
  
  def new
		@title = t(:signin)
    @user_session = UserSession.new
		@mail_message = session[:mail_message] if !session[:mail_message].nil?
  end
  
	def show
		redirect_to root_path
	end

  def create
		if params[:userlogin].length > 0
			render :text => ''
		else
			@user_session = UserSession.new(params[:user_session])

			# remember user_id if checkbox is checked
			if params[:user_session][:remember_id] == '1'
				cookies['user_id'] = { :value => params[:user_session][:login], :expires => 1.month.from_now }
			else
				cookies.delete 'user_id'
			end

			if @user_session.save
				redirect_to root_path and return
			else
				# prevent timing and brute force password attacks
				sleep 1
				@failed = true
				render :action => :new
			end
		end
  end
  
  def destroy
    current_user_session.destroy
		reset_session
		redirect_to root_path
  end
end