require 'spec_helper'

describe UsersController do
  before :each do
    @user = FactoryGirl.create(:user)
  end

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

  describe "login via api" do
    it "should return a token" do
      post :api_login, :login => @user.login, :password => @user.password
      @user.reload
      response.body.should eq(@user.authentication_token)
    end

    it "returns JSON" do
      post :api_login, :login => @user.login, :password => @user.password, :format => 'json'
      @user.reload
      JSON.parse(response.body)['login'].should eq(@user.login)
      JSON.parse(response.body)['authentication_token'].should eq(@user.authentication_token)
    end

    it "returns XML" do
      post :api_login, :login => @user.login, :password => @user.password, :format => 'xml'
      @user.reload
      Nokogiri::XML(response.body).css('login').text.should eq(@user.login)
      Nokogiri::XML(response.body).css('authentication-token').text.should eq(@user.authentication_token)
    end
  end

  describe "authentication via api" do
    it "should not allow authentication via incorrect token" do
      # attempt to get private profile info
      get :profile, :glob => @user.login, :format => 'json', :login => @user.login, :token => 'bad token'
      JSON.parse(response.body)['email'].should eq(nil)
    end

    it "should allow authentication via correct token" do
      # attempt to get private profile info
      get :profile, :glob => @user.login, :format => 'json', :login => @user.login, :token => @user.authentication_token
      JSON.parse(response.body)['email'].should eq(@user.email)
    end
  end

end

