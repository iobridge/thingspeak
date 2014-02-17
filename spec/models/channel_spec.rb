# encoding: UTF-8
# == Schema Information
#
# Table name: channels
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  name          :string(255)
#  description   :string(255)
#  latitude      :decimal(15, 10)
#  longitude     :decimal(15, 10)
#  field1        :string(255)
#  field2        :string(255)
#  field3        :string(255)
#  field4        :string(255)
#  field5        :string(255)
#  field6        :string(255)
#  field7        :string(255)
#  field8        :string(255)
#  scale1        :integer
#  scale2        :integer
#  scale3        :integer
#  scale4        :integer
#  scale5        :integer
#  scale6        :integer
#  scale7        :integer
#  scale8        :integer
#  created_at    :datetime
#  updated_at    :datetime
#  elevation     :string(255)
#  last_entry_id :integer
#  public_flag   :boolean          default(FALSE)
#  options1      :string(255)
#  options2      :string(255)
#  options3      :string(255)
#  options4      :string(255)
#  options5      :string(255)
#  options6      :string(255)
#  options7      :string(255)
#  options8      :string(255)
#  social        :boolean          default(FALSE)
#  slug          :string(255)
#  status        :string(255)
#  url           :string(255)
#  video_id      :string(255)
#  video_type    :string(255)
#  clearing      :boolean          default(FALSE), not null
#  ranking       :integer
#

require 'spec_helper'

describe Channel do
  it "should be valid" do
    channel = Channel.new
    channel.should be_valid
  end

  it "should accept utf8" do
    channel = Channel.create(:name => "ǎ")
    channel.reload
    channel.name.should == "ǎ"
  end

  it "should have no plugins when created" do
    channel = Channel.create
    channel.set_windows
    channel.save
    channel.name.should == "Channel #{channel.id}"
    channel.windows.size.should == 2
  end

  it "should have video iframe after updated" do
    channel = Channel.create!
    video_id = "xxxxxx"
    channel.assign_attributes({:video_id => video_id, :video_type => "youtube"})
    channel.set_windows
    channel.save
    window = channel.windows.where({:wtype => :video })
    window[0].html.should == "<iframe class=\"youtube-player\" type=\"text/html\" width=\"452\" height=\"260\" src=\"https://www.youtube.com/embed/xxxxxx?wmode=transparent\" frameborder=\"0\" wmode=\"Opaque\" ></iframe>"
  end

  it "should have private windows" do
    channel = Channel.create!
    channel.assign_attributes({:field1 => "Test"})
    channel.set_windows
    channel.save
    showFlag = true
    channel.private_windows(showFlag).count.should == 2 #2 private windows - 1 field and 1 status
  end

  # this is necessary so that the existing API is not broken
  # https://thingspeak.com/channels/9/feed.json?results=10 should have 'channel' as the first key
  it "should include root in json by default" do
    channel = Channel.create
    channel.as_json.keys.include?('channel').should be_true
  end

  it "should not include root using public_options" do
    channel = Channel.create
    channel.as_json(Channel.public_options).keys.include?('channel').should be_false
  end

  describe 'testing scopes' do
    before :each do
      @public_channel = FactoryGirl.create(:channel, :public_flag => true, :last_entry_id => 10)
      @private_channel = FactoryGirl.create(:channel, :public_flag => false, :last_entry_id => 10)
    end
    it 'should show public channels' do
      channels = Channel.public_viewable
      channels.count.should == 1
    end
    it 'should show active channels' do
      channels = Channel.active
      channels.count.should == 2
    end
    it 'should show selected channels' do
      channels = Channel.by_array([@public_channel.id, @private_channel.id])
      channels.count.should == 2
    end
    it 'should show tagged channels' do
      @public_channel.save_tags('sensor')
      channels = Channel.with_tag('sensor')
      channels.count.should == 1
    end
  end
end
