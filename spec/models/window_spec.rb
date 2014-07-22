# == Schema Information
#
# Table name: windows
#
#  id           :integer          not null, primary key
#  channel_id   :integer
#  position     :integer
#  created_at   :datetime
#  updated_at   :datetime
#  html         :text
#  col          :integer
#  title        :string(255)
#  window_type  :string(255)
#  name         :string(255)
#  private_flag :boolean          default(FALSE)
#  show_flag    :boolean          default(TRUE)
#  content_id   :integer
#  options      :text
#

require 'spec_helper'

describe Window do
  it "should be valid" do
    window = Window.new
    window.should be_valid
  end

  describe "plugin window" do
    before :each do
      @channel = FactoryGirl.create(:channel)
      @plugin = FactoryGirl.create(:plugin)
    end

    it "should be valid" do
      window = Window.new
      window.should be_valid
    end

    it "should allow windows plugin association" do
      window = Window.new_from @plugin, @channel.id, :private, "localhost"
      @plugin.windows << window
      @plugin.save
      window.should be_valid
      window.should_not be_nil
    end
  end

  describe "plugin window with user" do
    before :each do
      @user = FactoryGirl.create(:user)
      @channel = FactoryGirl.create(:channel, :user => @user)
      @plugin = FactoryGirl.create(:plugin, :user => @user)
    end

    it "should differentiate between public plugin_window and private plugin_window" do
      window = Window.new_from @plugin, @channel.id, true, "localhost"
      @plugin.windows << window
      @plugin.save
      @plugin.windows.length.should == 1

      window = Window.new_from @plugin, @channel.id, false, "localhost"
      @plugin.windows << window
      @plugin.save
      @plugin.windows.length.should == 2
    end

  end
end

