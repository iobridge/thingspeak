require 'spec_helper'

describe FeedController do
  before :each do
    @user = FactoryGirl.create(:user)
    @channel = FactoryGirl.create(:channel)
    now = Time.utc(2013,1,1)
    @feed1 = FactoryGirl.create(:feed, :field1 => 10, :channel => @channel, :created_at => now, :entry_id => 1)
    @feed = FactoryGirl.create(:feed, :field1 => 10, :channel => @channel, :created_at => now, :entry_id => 2)
    @feed = FactoryGirl.create(:feed, :field1 => 9, :channel => @channel, :created_at => now, :entry_id => 3)
    @feed = FactoryGirl.create(:feed, :field1 => 7, :channel => @channel, :created_at => now, :entry_id => 4)
    @feed = FactoryGirl.create(:feed, :field1 => 6, :channel => @channel, :created_at => now, :entry_id => 5)
    @feed = FactoryGirl.create(:feed, :field1 => 5, :channel => @channel, :created_at => now, :entry_id => 6)
    @feed = FactoryGirl.create(:feed, :field1 => 4, :channel => @channel, :created_at => now, :entry_id => 7)
    @channel.last_entry_id = @feed.entry_id
    @channel.field1 = 'temp'
    @channel.save

    @user.channels.push @channel
    @tag = FactoryGirl.create(:tag)
    @apikey = FactoryGirl.create(:api_key)
    controller.stub(:current_user).and_return(@user)
    controller.stub(:current_user_session).and_return(true)

  end

  it "should get first feed" do
    get :show, {id: @feed1.id, channel_id: @channel.id, format: 'json'}
    response.should be_successful
    response.body.should eq("{\"created_at\":\"2013-01-01T00:00:00+00:00\",\"entry_id\":1,\"field1\":\"10\"}" )
  end

  it "should get last feed" do
    get :show, {id: 'last', channel_id: @channel.id, format: 'json'}
    response.should be_successful
    response.body.should eq("{\"created_at\":\"2013-01-01T00:00:00+00:00\",\"entry_id\":7,\"field1\":\"4\"}" )
  end

  it "should get last feed (html)" do
    get :show, {id: 'last', channel_id: @channel.id, field_id: 1}
    response.should be_successful
    response.body.should eq("4" )
  end

  it "should get last feed (html), no field_id specified" do
    get :show, {id: 'last', channel_id: @channel.id}
    response.should be_successful
    response.body.should eq("{\"created_at\":\"2013-01-01T00:00:00+00:00\",\"entry_id\":7,\"field1\":\"4\"}" )
  end

  it "should get feed last_average" do
    get :last_average, {channel_id: @channel.id, average: 10}
    response.should be_successful
    jsonResponse = JSON.parse(response.body)

    jsonResponse["field1"].should eq("7.285714285714286")

  end

  it "should get last_median" do
    get :last_median, {channel_id: @channel.id, median: 10}
    response.should be_successful
    jsonResponse = JSON.parse(response.body)
    jsonResponse["field1"].should eq("7.0")
  end

  it "should get last_sum" do
    get :last_sum, {channel_id: @channel.id, sum: 10}
    response.should be_successful
    jsonResponse = JSON.parse(response.body)
    jsonResponse["field1"].should eq("51.0")
  end

end

