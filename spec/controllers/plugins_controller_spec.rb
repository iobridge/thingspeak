require 'spec_helper'

describe PluginsController do
 before :each do
    @user = FactoryGirl.create(:user)
    @plugin = FactoryGirl.create(:plugin, :user => @user)
    @channel = FactoryGirl.create(:channel, :user => @user)
  end

  describe "GET 'private_plugins' for plugin" do
    before :each do
      controller.stub(:current_user).and_return(@user)
      controller.stub(:current_user_session).and_return(true)
    end

    it "should return plugin windows" do
      get 'private_plugins', :channel_id => @channel.id
      response.should be_successful
    end
  end

  describe "Not Logged In" do
    #it "should display public plugins" do
    #  get :public
    #  response.should render_template('public')
    #end

    #it "should show paginated list of public plugins as json" do
    #  @plugin.update_column(:public_flag, true)
    #  get :public, :format => :json
    #  JSON.parse(response.body).keys.include?('pagination').should be_true
    #  JSON.parse(response.body)['plugins'].length.should eq(1)
    #end

    #it "should not show private plugins" do
    #  @plugin.update_column(:public_flag, false)
    #  get :public, :format => :json
    #  JSON.parse(response.body)['plugins'].length.should eq(0)
    #end
  end

  describe "API" do
    describe "list plugins" do
      it "should not list my plugins" do
        get :index, {:api_key => 'INVALID', :format => 'json'}
        response.status.should eq(401)
      end

      it "lists my plugins" do
        get :index, {:api_key => @user.api_key, :format => 'json'}
        response.should be_successful
      end
    end
  end
end

