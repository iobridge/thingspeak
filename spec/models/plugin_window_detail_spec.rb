# == Schema Information
#
# Table name: plugin_window_details
#
#  id               :integer          not null, primary key
#  plugin_id        :integer
#  plugin_window_id :integer
#  created_at       :datetime
#  updated_at       :datetime
#

require 'spec_helper'

describe PluginWindowDetail do
  before :each do
    @channel = FactoryGirl.create(:channel)      
    @plugin = FactoryGirl.create(:plugin)      
  end

  it "should be valid" do
    winDetail = PluginWindowDetail.new
    winDetail.should be_valid
  end
  it "should allow windows plugin association" do
    window = Window.new_from @plugin, @channel.id, :private, "localhost"
    @plugin.windows << window
    @plugin.save
    window.should be_valid

    window.window_detail.should_not be_nil
  end
end

describe PluginWindowDetail do
  before :each do
    @user = FactoryGirl.create(:user)
    @channel = FactoryGirl.create(:channel, :user => @user)
    @plugin = FactoryGirl.create(:plugin, :user => @user) 
  end
  it "should differentiate between public plugin_window and private plugin_window" do

    window = Window.new_from @plugin, @channel.id, true, "localhost"
    @plugin.windows << window
    @plugin.save
    plugin = PluginWindowDetail.find_all_by_plugin_id(@plugin.id)
    plugin.length.should == 1

    window = Window.new_from @plugin, @channel.id, false, "localhost"
    @plugin.windows << window
    @plugin.save
    plugin = PluginWindowDetail.find_all_by_plugin_id(@plugin.id)
    plugin.length.should == 2
  end
end
