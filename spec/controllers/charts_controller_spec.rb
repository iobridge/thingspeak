require 'spec_helper'

describe ChartsController do
  before :each do
    @user = FactoryGirl.create(:user)
    
    controller.stub(:current_user).and_return(@user)
    controller.stub(:current_user_session).and_return(true)
    @channel = FactoryGirl.create(:channel, :user => @user)



  end
  
  describe "responding to a GET index" do
    render_views
    it "has a 'select' selector for 'dynamic'" do
      get :index, :channel_id => @channel.id
      response.should be_successful
      response.should have_selector("select#dynamic_0")
    end
  end

end
