require 'spec_helper'

describe UsersController do
  before :each do
    @user = FactoryGirl.create(:user)
    # controller.stub(:current_user).and_return(@user)
    # controller.stub(:current_user_session).and_return(true)
    # @channel = FactoryGirl.create(:channel)
  end

  # create a valid authlogic session
  #def create_valid_session
  #  activate_authlogic
  #  UserSession.create(@user, true) #create an authlogic session
  #end

  # get the curent_user
  #def current_user; @current_user ||= @user; end

  describe "api" do
    render_views

    it "should show login in public json info" do
      get :profile, :glob => @user.login, :format => 'json'
      JSON.parse(response.body)['login'].should eq(@user.login)
    end

    it "should not show email in public json info" do
      get :profile, :glob => @user.login, :format => 'json'
      JSON.parse(response.body)['email'].should eq(nil)
    end

    it "should show email in private json info" do
      get :profile, :glob => @user.login, :format => 'json', :key => @user.api_key
      JSON.parse(response.body)['email'].should eq(@user.email)
    end

  end

  #describe "existing account" do
    #render_views

    #it "has a current_user" do
    #  create_valid_session
    #  current_user.should_not be_false
    #end

    #it "generates a new api_key" do
    #  create_valid_session
    #  old_key = @user.set_new_api_key!
    #  post :new_api_key
    #  response.should be_successful
    #  assigns[:user].api_key.should != old_key
    #end
  #end

  describe "new account" do
    render_views

    it "assigns new user" do
      get :new
      response.should be_successful
      response.should have_selector("#user_submit")
      assigns[:user].should_not be_nil
    end
    it "should create a new user if user parameters are complete" do
      post :create, :user => {"login"=>"xxx", "email"=>"xxx@insomnia-consulting.org", "time_zone"=>"Eastern Time (US & Canada)", "password"=>"[FILTERED]", "password_confirmation"=>"[FILTERED]"}
      response.code.should == "302"
      response.should redirect_to(channels_path)
    end

    it "should have a valid api_key" do
      post :create, :user => {"login"=>"xxx", "email"=>"xxx@insomnia-consulting.org", "password"=>"[FILTERED]", "password_confirmation"=>"[FILTERED]"}
      assigns[:user].api_key.length.should eq(16)
    end

  end

end

