# == Schema Information
#
# Table name: plugins
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  user_id     :integer
#  html        :text
#  css         :text
#  js          :text
#  created_at  :datetime
#  updated_at  :datetime
#  public_flag :boolean          default(FALSE)
#

require 'spec_helper'

describe Plugin do

  before :each do
    @user = FactoryGirl.create(:user)
    @channel = FactoryGirl.create(:channel, :user => @user)
    @window = FactoryGirl.create(:window, :channel => @channel, :html => "<iframe ::OPTIONS::></iframe>")

  end
  it "should be valid" do
    plugin = Plugin.new
    plugin.should be_valid
  end

  it "should confirm has_[public\private]_windows" do
    plugin = Plugin.new

    window = Window.new
    window.private_flag = true
    window.channel_id = 1
    plugin.windows << window

    plugin.has_private_windows(1).should be_true
    plugin.has_public_windows(1).should be_false
  end

  it "new, public plugin should get 2 plugin windows" do
    plugin = Plugin.new
    plugin.public_flag = true
    plugin.public?.should be_true
    #Private plugins have one window..
    #Public plugins have a private window and a public window

    plugin.make_windows @channel.id, "localhost"
    plugin.windows.size.should eq(2)

  end

  it "new, private window should not be showing" do
    plugin = Plugin.new
    plugin.public_flag = false
    plugin.public?.should be_false
    #Private plugins have one window..

    plugin.make_windows @channel.id, "localhost"
    plugin.windows.size.should eq(1)
    window = plugin.windows[0]
    window.show_flag.should be_false

  end

  it "should destroy public windows when changing plugin from public to private" do
    plugin = Plugin.new
    plugin.public_flag = false
    plugin.public?.should be_false
    #Private plugins have one window..
    plugin.make_windows @channel.id, "localhost"
    plugin.windows.size.should eq(1)

    plugin.public_flag = true
    plugin.save

    plugin.make_windows @channel.id, "localhost"
    plugin.windows.size.should eq(2)

    plugin.public_flag = false
    plugin.save
    plugin.make_windows @channel.id, "localhost"
    plugin.windows.size.should eq(1)
  end

  it "should allow only private_windows to be retrieved" do
    plugin = Plugin.new
    plugin.public_flag = true
    plugin.public?.should be_true
    #Private window has private_dashboard_visibility only
    plugin.make_windows @channel.id, "localhost"
    plugin.windows.size.should eq(2)
    plugin.private_dashboard_windows(@channel.id).size.should eq(1)
  end

  it "should allow only public_windows to be retrieved" do
    plugin = Plugin.new
    plugin.public_flag = true
    plugin.public?.should be_true
    #Private window has private_dashboard_visibility only
    plugin.make_windows @channel.id, "localhost"
    plugin.windows.size.should eq(2)
    plugin.public_dashboard_windows(@channel.id).size.should eq(1)
  end

  it "should cascade delete to Window" do
    plugin = Plugin.new
    plugin.make_windows @channel.id, "localhost"
    plugin_id = plugin.id
    plugin.destroy
    Window.where(window_type: 'plugin', content_id: plugin_id).count.should eq(0)
  end

  it "should have windows associated with separate channels" do
    channel2 = FactoryGirl.create(:channel, :user => @user)
    plugin = Plugin.new
    plugin.make_windows @channel.id, "localhost"
    plugin.make_windows channel2.id, "localhost"
    plugin.windows.size.should eq(2)
    plugin.private_dashboard_windows(@channel.id).size.should eq(1)
    plugin.private_dashboard_windows(channel2.id).size.should eq(1)

  end
end

