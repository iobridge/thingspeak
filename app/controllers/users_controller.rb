class UsersController < ApplicationController
  include KeyUtilities
  before_filter :require_no_user, :only => [:new, :create, :forgot_password]
  before_filter :require_user, :only => [:show, :edit, :update, :change_password, :edit_profile]

  # generates a new api key
  def new_api_key
    current_user.set_new_api_key!
    redirect_to account_path
  end

  # edit public profile
  def edit_profile
    @user = current_user
  end

  # update public profile
  def update_profile
    @user = current_user # makes our views "cleaner" and more consistent
    # update
    @user.update_attributes(user_params)
    redirect_to account_path
  end

  # public profile for a user
  def profile
    # set params and request.format correctly
    set_request_details!(params)

    @user = User.find_by_login(params[:id])

    # output error if user not found
    render :text => t(:user_not_found) and return if @user.nil?

    # if a json or xml request
    if request.format == :json || request.format == :xml
      # authenticate the user if api key matches the target user
      authenticated = (User.find_by_api_key(get_apikey) == @user)
      # set options correctly
      options = authenticated ? User.private_options : User.public_options(@user)
    end

    respond_to do |format|
      format.html
      format.json { render :json => @user.as_json(options) }
      format.xml { render :xml => @user.to_xml(options) }
    end
  end

  # list all public channels for a user
  def list_channels
    @user = User.find_by_login(params[:id])

    # output error if user not found
    render :text => t(:user_not_found) and return if @user.nil?

    # if html request
    if request.format == :html
      @title = "Internet of Things - Public Channels for #{@user.login}"
      @channels = @user.channels.public_viewable.paginate :page => params[:page], :order => 'last_entry_id DESC'
    # if a json or xml request
    elsif request.format == :json || request.format == :xml
      # authenticate the user if api key matches the target user
      authenticated = (User.find_by_api_key(get_apikey) == @user)
      # get all channels if authenticated, otherwise only public ones
      channels = authenticated ? @user.channels : @user.channels.public_viewable
      # set channels correctly
      @channels = { channels: channels.as_json(Channel.public_options) }
    end

    respond_to do |format|
      format.html
      format.json { render :json => @channels }
      format.xml { render :xml => @channels.to_xml(:root => 'response') }
    end
  end

  def new
    @title = t(:signup)
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.api_key = generate_api_key(16, 'user')

    # save user
    if @user.valid?

      if @user.save
        redirect_back_or_default channels_path and return
      end
    else
      render :action => :new
    end

  end

  def show
    @menu = 'account'
    @user = @current_user
  end

  def edit
    @menu = 'account'
    @user = @current_user
  end

  # displays forgot password page
  def forgot_password
    @user = User.new
  end

  # this action is called from an email link when a password reset is requested
  def reset_password
    # if user has been logged in (due to previous form submission)
    if !current_user.nil?
      @user = current_user
      @user.errors.add(:base, t(:password_problem))
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
    @user = current_user
    # if no password entered, redirect
    redirect_to reset_password_path and return if params[:user][:password].empty?
    # check current password and update
    if @user.update_attributes(user_params)
      redirect_to account_path
    else
      redirect_to reset_password_path
    end
  end

  def update
    @menu = 'account'
    @user = @current_user # makes our views "cleaner" and more consistent
    # check current password and update
    if @user.valid_password?(params[:password_current]) && @user.update_attributes(user_params)
      redirect_to account_path
    else
      @user.errors.add(:base, t(:password_incorrect))
      render :action => :edit
    end
  end

  private

    # only allow these params
    def user_params
      params.require(:user).permit(:email, :login, :time_zone, :public_flag, :bio, :website, :password, :password_confirmation)
    end

    # set params[:id] and request.format correctly
    def set_request_details!(params)
      # set format
      new_format = 'html' if params[:glob].end_with?('.html')
      new_format = 'json' if params[:glob].end_with?('.json')
      new_format = 'xml' if params[:glob].end_with?('.xml')

      # remove the format from the end of the glob
      params[:id] = params[:glob].chomp(".#{new_format}")

      # set the new format if it exists
      request.format = new_format.to_sym if new_format.present?
    end

end

