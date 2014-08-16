require 'spec_helper'

describe ChannelsController do

  describe "Logged In" do
    before :each do
      @user = FactoryGirl.create(:user)
      @channel = FactoryGirl.create(:channel)
      @user.channels.push @channel
      @tag = FactoryGirl.create(:tag)
      @apikey = FactoryGirl.create(:api_key)
      controller.stub(:current_user).and_return(@user)
      controller.stub(:current_user_session).and_return(true)

    end
    it "should show the channels private page" do
      get :show, :id => @channel.id
      response.should render_template(:private_show)
    end

    it "should allow a new channel to be created" do
      post :create
      channel = Channel.last
      response.should be_redirect
      response.should redirect_to( channel_path(channel.id, :anchor => "channelsettings"))
      channel.windows.where(window_type: 'chart').count.should eq(2)
    end

    it "should allow a channel to be edited" do
      @channel.public_flag = true
      put :update, id: @channel, channel: {name: 'new name'}, tags: FactoryGirl.attributes_for(:tag)
      @channel.reload
      @channel.name.should eq('new name')
      response.should redirect_to channel_path(@channel.id)
    end

    it "should allow a channel to be deleted " do
      delete :destroy, :id => @channel.id
      response.should redirect_to channels_path
      @channel_no_more = Channel.find_by_id(@channel.id)
      @channel_no_more.should be_nil
    end
  end

  describe "Not Logged In" do
    before :each do
      without_timestamping_of Channel do
        @channel = FactoryGirl.create(:channel, :updated_at => Time.now - RATE_LIMIT_FREQUENCY.to_i.seconds, :public_flag => false)
      end
      @apikey = FactoryGirl.create(:api_key, :channel => @channel)
    end

    it "should only display public channels" do
      get :public
      response.should render_template('public')
    end

    it "should show paginated list of public channels as json" do
      get :public, :format => :json
      JSON.parse(response.body).keys.include?('pagination').should be_true
    end

    it "should show the channels public page" do
      get :show, :id => @channel.id
      response.should render_template(:public_show)
    end

    it "should redirect to login when creating a new channel" do
      post :create

      response.should be_redirect
      response.should redirect_to(login_path)
      response.status.should == 302
    end

    it "should be allowed to send data via get to update channel" do
      get :post_data, {:key => "0S5G2O7FAB5K0J6Z", :field1 => "0", :status => "ThisIsATest"}

      response.body.to_i.should > 0
      response.should be_successful
    end

    if defined?(React)
      describe "updates a channel and executes a TalkBack command" do
        before :each do
          @talkback = FactoryGirl.create(:talkback)
          @command = FactoryGirl.create(:command)
          @command2 = FactoryGirl.create(:command, :position => nil, :command_string => 'quote"test')
        end

        it 'returns the command string' do
          post :post_data, {:key => '0S5G2O7FAB5K0J6Z', :field1 => '70', :talkback_key => @talkback.api_key}
          response.body.should eq("MyString")
        end
        it 'returns JSON' do
          post :post_data, {:key => '0S5G2O7FAB5K0J6Z', :field1 => '70', :talkback_key => @talkback.api_key, :format => 'json'}
          JSON.parse(response.body)['command_string'].should eq("MyString")
          JSON.parse(response.body)['position'].should eq(nil)
          JSON.parse(response.body)['executed_at'].should_not eq(nil)
        end
        it 'returns XML' do
          post :post_data, {:key => '0S5G2O7FAB5K0J6Z', :field1 => '70', :talkback_key => @talkback.api_key, :format => 'xml'}
          Nokogiri::XML(response.body).css('command-string').text.should eq("MyString")
          Nokogiri::XML(response.body).css('position').text.should eq('')
          Nokogiri::XML(response.body).css('executed-at').text.should_not eq('')
        end
      end
    end

  end

  describe "API" do
    before :each do
      @user = FactoryGirl.create(:user)
      @channel = FactoryGirl.create(:channel)
      @feed = FactoryGirl.create(:feed, :field1 => 10, :channel => @channel)
    end

    describe "list channels" do
      it "should not list my channels" do
        get :index, {:api_key => 'INVALID', :format => 'json'}
        response.status.should eq(401)
      end

      it "lists my channels" do
        get :index, {:api_key => @user.api_key, :format => 'json'}
        response.should be_successful
      end

      it "searches nearby public channels" do
        channel1 = Channel.create(name: 'channel1', latitude: 10, longitude: 10, public_flag: true)
        channel2 = Channel.create(name: 'channel2', latitude: 60, longitude: 60, public_flag: true)
        get :public, {api_key: @user.api_key, latitude: 59.8, longitude: 60.2, distance: 100, format: 'json'}
        JSON.parse(response.body)['channels'][0]['name'].should eq("channel2")
      end
    end

    describe "show channel" do
      it 'shows a channel' do
        get :show, id: @channel.id
        response.should be_successful
      end
      it 'returns JSON' do
        get :show, id: @channel.id, format: 'json'
        JSON.parse(response.body)['name'].should eq(@channel.name)
        JSON.parse(response.body)['api_keys'].should be_nil
      end
      it 'returns JSON with private data' do
        get :show, id: @channel.id, api_key: @user.api_key, format: 'json'
        JSON.parse(response.body)['api_keys'].should_not be_nil
      end
      it 'returns XML' do
        get :show, id: @channel.id, format: 'xml'
        Nokogiri::XML(response.body).css('name').text.should eq(@channel.name)
        Nokogiri::XML(response.body).css('api-keys').text.should be_blank
      end
      it 'returns XML with private data' do
        @channel.add_write_api_key
        get :show, id: @channel.id, api_key: @user.api_key, format: 'xml'
        Nokogiri::XML(response.body).css('api-keys').text.should_not be_blank
      end
    end

    describe "create channel" do
      it 'creates a channel' do
        post :create, {:key => @user.api_key, :name => 'mychannel'}
        response.should be_redirect
        channel_id = Channel.all.last.id
        response.should redirect_to(channel_path(channel_id, :anchor => "channelsettings"))
      end
      it 'returns JSON' do
        post :create, {:key => @user.api_key, :name => 'mychannel', :format => 'json'}
        Channel.last.ranking.should_not be_blank
        JSON.parse(response.body)['name'].should eq("mychannel")
      end
      it 'returns XML' do
        post :create, {:key => @user.api_key, :name => 'mychannel', :description => 'mydesc', :format => 'xml'}
        Nokogiri::XML(response.body).css('description').text.should eq("mydesc")
      end
    end

    describe "update channel" do
      it 'updates a channel' do
        post :update, {:id => @channel.id, :key => @user.api_key, :name => 'newname'}
        response.should be_redirect
        @channel.reload
        @channel.name.should eq("newname")
        channel_id = Channel.all.last.id
        response.should redirect_to(channel_path(channel_id))
      end
      it 'returns JSON' do
        post :update, {:id => @channel.id, :key => @user.api_key, :name => 'newname', :format => 'json'}
        Channel.last.ranking.should_not be_blank
        JSON.parse(response.body)['name'].should eq("newname")
      end
      it 'returns XML' do
        post :update, {:id => @channel.id, :key => @user.api_key, :name => 'newname', :format => 'xml'}
        Nokogiri::XML(response.body).css('name').text.should eq("newname")
      end
    end

    describe "clear channel" do
      it 'clears a channel' do
        @channel.feeds.count.should eq(1)
        delete :clear, {:id => @channel.id, :key => @user.api_key}
        @channel.feeds.count.should eq(0)
        response.should be_redirect
        response.should redirect_to(channel_path(@channel.id))
      end
      it 'returns JSON' do
        @channel.feeds.count.should eq(1)
        delete :clear, {:id => @channel.id, :key => @user.api_key, :format => 'json'}
        @channel.feeds.count.should eq(0)
        JSON.parse(response.body).should eq([])
      end
      it 'returns XML' do
        @channel.feeds.count.should eq(1)
        delete :clear, {:id => @channel.id, :key => @user.api_key, :format => 'xml'}
        @channel.feeds.count.should eq(0)
        Nokogiri::XML(response.body).css('nil-classes').text.should eq('')
      end
    end

    describe "delete channel" do
      it 'deletes a channel' do
        delete :destroy, {:id => @channel.id, :key => @user.api_key}
        Channel.find_by_id(@channel.id).should be_nil
        response.should be_redirect
        response.should redirect_to(channels_path)
      end
      it 'returns JSON' do
        delete :destroy, {:id => @channel.id, :key => @user.api_key, :format => 'json'}
        Channel.find_by_id(@channel.id).should be_nil
        JSON.parse(response.body)['name'].should eq(@channel.name)
      end
      it 'returns XML' do
        delete :destroy, {:id => @channel.id, :key => @user.api_key, :format => 'xml'}
        Channel.find_by_id(@channel.id).should be_nil
        Nokogiri::XML(response.body).css('name').text.should eq(@channel.name)
      end
    end

  end

end

