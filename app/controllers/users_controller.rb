class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create, :forgot_password]
  before_filter :require_user, :only => [:show, :edit, :update, :change_password]

  def new
		@title = t(:signup)
    @user = User.new
  end
  
  def create
		@user = User.new(params[:user])

		# save user
		if @user.valid?
			if @user.save
				redirect_back_or_default account_path
			end	
		else
			render :action => :new
		end

  end
  
  def show
		@menu = 'account'
    @user = current_user
  end
 
  def edit
		@menu = 'account'
    @user = current_user
  end

	# displays forgot password page
	def forgot_password
	end

	# this action is called from an email link when a password reset is requested
	def reset_password
		# if user has been logged in (due to previous form submission)
		if !current_user.nil?
			@user = current_user
			@user.errors.add(t(:password_problem))
			@valid_link = true
		else
			@user = User.find_by_id(params[:id])
			# make sure tokens match and password reset is within last 10 minutes
			if @user.perishable_token == params[:token] && @user.updated_at > 600.seconds.ago
				@valid_link = true
				# log the user in
				@user_session = UserSession.new(@user)
				@user_session.save
			end
		end
	end

	# do the actual password change
	def change_password
		# protect against bots
		render :text => '' and return if params[:userlogin].length > 0

    @user = current_user
		# if no password entered, redirect
		redirect_to reset_password_path and return if params[:user][:password].empty?
		# check current password and update
		if @user.update_attributes(params[:user])
      redirect_to account_path
    else
      redirect_to reset_password_path
    end
	end

  def update
		@menu = 'account'
    @user = current_user # makes our views "cleaner" and more consistent
		# check current password and update
		if @user.valid_password?(params[:password_current]) && @user.update_attributes(params[:user])
      redirect_to account_path
    else
      @user.errors.add :base, t(:password_incorrect)
      render :edit      
    end
  end

end