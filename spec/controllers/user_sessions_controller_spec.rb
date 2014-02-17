# -*- coding: utf-8 -*-
require 'spec_helper'

describe UserSessionsController do
  before :each do
    @user = FactoryGirl.create(:user)
    activate_authlogic
    @user_session = UserSession.create(@user)
    controller.stub(:current_user).and_return(@user)
    controller.stub(:current_user_session).and_return(@user_session)
  end
  
  describe "for logged in user" do
    it "should logout the user" do
      get 'destroy'
      response.should redirect_to(root_path)
    end
  end
end

describe UserSessionsController do
   before :each do
     @user = FactoryGirl.create(:user)
     activate_authlogic
#     @user_session = UserSession.create(@user)
#     controller.stub(:current_user).and_return(@user)
#     controller.stub(:current_user_session).and_return(@user_session)
   end
   it "should allow a new user to login" do
     get 'new'
     response.should be_success
    response.should render_template('new')
   end  

  it "should create user session" do
    post 'create' , {:userlogin => "", :user_session=>{"remember_me"=>"false", "login"=>@user.login, "password"=>"foobar", "remember_id"=>"1"}, "commit" => "Sign In"}
    user_session = UserSession.find
    user_session.should_not be_nil
    user_session.user.should == @user
    response.should redirect_to ('/channels')
    
  end

end
