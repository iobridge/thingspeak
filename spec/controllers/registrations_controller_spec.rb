require 'spec_helper'

describe RegistrationsController do

  describe "new account" do
    render_views

    it "should create a new user if user parameters are complete" do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      post :create, :user => {"login"=>"xxx", "email"=>"xxx@insomnia-consulting.org", "time_zone"=>"Eastern Time (US & Canada)", "password"=>"[FILTERED]", "password_confirmation"=>"[FILTERED]"}
      response.code.should == "302"
      response.should redirect_to(channels_path)
    end

    it "should have a valid api_key" do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      post :create, :user => {"login"=>"xxx", "email"=>"xxx@insomnia-consulting.org", "password"=>"[FILTERED]", "password_confirmation"=>"[FILTERED]"}
      assigns[:user].api_key.length.should eq(16)
    end

  end

end

