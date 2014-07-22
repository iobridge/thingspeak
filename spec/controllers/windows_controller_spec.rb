require 'spec_helper'

describe WindowsController do
  before :each do
    @user = FactoryGirl.create(:user)

    controller.stub(:current_user).and_return(@user)
    controller.stub(:current_user_session).and_return(true)

    @channel = FactoryGirl.create(:channel, :user => @user)

    @window = FactoryGirl.create(:window)
    @channel.windows << @window

  end

  describe "PUT 'hide' for window" do
    it "should update the show_flag on that window" do
      put 'hide', :channel_id => @channel.id, :id => @window.id
      response.should be_successful
    end
  end

  describe "POST 'update'" do
    it "should allow an update" do
      post 'update', :channel_id => @channel.id, :page => "{\"col\":0,\"positions\":[#{@window.id}]}"
      response.should be_success
    end
  end

  describe "POST 'update' with invalid position" do

    it "should fail" do
      post 'update', :channel_id => @channel.id, :page => "{\"col\":0,\"positions\":[999]}"
      response.should be_success
    end
  end
  describe "When getting " do

    it "should render private_windows json" do
      get 'private_windows', :channel_id => @channel.id, :format => :json
      response.should be_successful
    end
    it "should render show_flag = false" do
      @channel.windows[0].show_flag = false
      @channel.save
      get 'hidden_windows', {:channel_id => @channel.id, :visibility_flag => "private" }, :format => :json

      response.status.should == 200
    end
  end

end

describe WindowsController do
  render_views
  before :each do
    @channel = FactoryGirl.create(:channel)
    @window = FactoryGirl.create(:window, html: "<iframe src=\"/\"/>")
    @channel.windows << @window
  end

  describe "POST 'update'" do
    it "should fail with no current user" do
      post 'update', :channel_id => @channel.id, :page => "{\"col\":0,\"positions\":[" + @window.id.to_s + "]}"
      response.status.should == 302
    end
  end


  describe "When getting " do
    it "should render json" do
      get 'index', :channel_id => @channel.id, :format => :json
      response.status.should == 200
      response.body == @channel.windows.to_json
    end


    it "should not render show_flag = false" do

      @channel.windows.each do |window|
        window.show_flag = false
      end
      saved = @channel.save
      saved.should be_true

      get 'index', :channel_id => @channel.id, :format => :json

      response.status.should == 200

      result = JSON.parse(response.body)
      result.size.should == 0
    end

  end

  describe "GET 'iframe' for window" do
    it "should return html with gsub for iframe" do
      get 'iframe', :channel_id => @channel.id, :id => @window.id
      response.should be_success
      response.body.should == "<iframe src=\"http://test.host/\"/>"
    end
    it "should render json" do
      @channel.windows[0].show_flag = false
      @channel.save
      get 'index', :channel_id => @channel.id, :format => :json

      response.status.should == 200
      response.body == @channel.windows.to_json

    end
  end

  describe "GET 'html' for window" do
    it "should return html" do
      get 'html', :channel_id => @channel.id, :id => @window.id

      response.should be_success
      response.body.should == "<iframe src=\"/\"/>"
    end
  end
  describe "PUT 'hide' for window" do
    it "should return a redirect to login_path for no current_user" do
      put 'hide', :channel_id => @channel.id, :id => @window.id
      response.should redirect_to(login_path)
    end
  end

end

