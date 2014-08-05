# == Schema Information
#
# Table name: daily_feeds
#
#  id          :integer          not null, primary key
#  channel_id  :integer
#  date        :date
#  calculation :string(20)
#  result      :string(255)
#  field       :integer
#

class DailyFeed < ActiveRecord::Base
  belongs_to :channel

  self.include_root_in_json = false

  # update a feed if it exists, or else create it
  def self.my_create_or_update(attributes)
    # try to get daily feed
    daily_feed = DailyFeed.where(attributes).first
    # if there is an existing daily feed
    if daily_feed.present?
      # update it
      daily_feed.update_attributes(attributes)
    # else create it
    else
      daily_feed = DailyFeed.create(attributes)
    end
  end

  # gets the calculation type
  def self.calculation_type(params)
    output = nil
    output = 'timescale' if params[:timescale].present?
    output = 'sum' if params[:sum].present?
    output = 'average' if params[:average].present?
    output = 'median' if params[:median].present?
    return output
  end

  # checks to see if this is a daily feed, only works for timezone UTC (offset == 0)
  def self.valid_params(params)
    daily_params = (params[:timescale] == '1440' || params[:sum] == '1440' || params[:average] == '1440' || params[:median] == '1440') ? true : false
    return daily_params && (Time.zone.name == 'UTC')
  end

end

