require 'spec_helper'

describe PluginsController do
 before :each do
    @user = FactoryGirl.create(:user)
    controller.stub(:current_user).and_return(@user)
    controller.stub(:current_user_session).and_return(true)

    @plugin = FactoryGirl.create(:plugin, :user => @user)
    @channel = FactoryGirl.create(:channel, :user => @user)
  end

  describe "GET 'private_plugins' for plugin" do
    it "should return plugin windows" do
      get 'private_plugins', :channel_id => @channel.id
      response.should be_successful
    end
  end

end
