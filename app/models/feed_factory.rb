class FeedFactory < ApplicationController
  include FeedHelper

  def initialize(options = {})
    @options = options # alias for params
    @feeds = nil
    @daily_feeds = nil
    @output_feeds = nil
    @rounded = false
    @channel = Channel.find(options[:channel_id])
    @date_range = get_date_range(options)
    @daily_date_range = @date_range.first.to_date..@date_range.last.to_date
    @limit = calculate_limit
    @use_daily_feed = DailyFeed.valid_params(options) # determine whether daily feed should be used
    @calculation_type = DailyFeed.calculation_type(options) # set the calculation type
    @feed_select_options = Feed.select_options(@channel, @options)
    @cache_feeds = cache_feeds?
  end

  # attributes that can be read
  attr_reader :feeds, :daily_feeds, :limit, :use_daily_feed, :feed_select_options, :cache_feeds, :channel

  # range for entry_ids
  def entry_id_range
    # set start and end id
    start_id = @options[:start_entry_id].present? ? @options[:start_entry_id].to_i : 1
    end_id = @options[:end_entry_id].present? ? @options[:end_entry_id].to_i : @channel.last_entry_id
    # return the range
    return start_id..end_id
  end

  # calculate the limit that should be used
  def calculate_limit
    limit = 100
    limit = 8000 if @options[:results].present? || @options[:days].present? || @options[:start].present? || @options[:end].present?
    limit = @options[:results].to_i if (@options[:results].present? && @options[:results].to_i < 8000)
    return limit
  end

  # determine if data should be cached
  def cache_feeds?
    cache = false
    cache = true if (@channel.last_entry_id.present? && @channel.last_entry_id > 100 && @limit > 100)
    cache = true if @options[:days].present?
    return cache
  end

  # if daily feeds exist, use that first, or else use regular feeds
  def get_output_feeds
    # get daily feeds
    get_daily_feeds if @use_daily_feed == true

    # get feeds normally if no daily feeds
    get_feeds if @daily_feeds.blank?

    # set minimum and maximum parameters, and round output feeds
    format_output_feeds

    return @output_feeds
  end

  # get feed for a date
  def get_feed_data_for_date(date)
    # get feeds for this date
    feeds = Feed.where(:channel_id => @channel.id, :created_at => date..(date + 1.day))
      .select(@feed_select_options).order('created_at asc').load

    # calculate the feed
    feed = calculate_feeds(feeds).first

    # add blank feed for this date if necessary
    feed = Feed.new(:created_at => date) if feed.nil?

    return feed
  end

  # add a daily feed for a specific date
  def add_daily_feed_for_date(date)
    # get the feed data
    feed = get_feed_data_for_date(date)

    # for each attribute
    @feed_select_options.each do |attr|
      key = attr.to_s
      # if this attribute is a field
      if key.index('field') == 0
        # get the field number
        field_number = key.sub('field', '').to_i
        # add the feed; replace with Rails 4 create_or_update if appropriate
        DailyFeed.my_create_or_update({:channel_id => @channel.id, :date => feed.created_at, :calculation => @calculation_type, :field => field_number, :result => feed[key]})
      end
    end

    # add to existing daily feeds
    @daily_feeds << feed
  end

  # get feeds
  def get_feeds
    # get feeds based on entry ids
    if @options[:start_entry_id].present? || @options[:end_entry_id].present?
      @feeds = Feed.from("feeds FORCE INDEX (index_feeds_on_channel_id_and_entry_id)")
        .where(:channel_id => @channel.id, :entry_id => entry_id_range)
    # get feed based on conditions
    else
      @feeds = Feed.from("feeds FORCE INDEX (index_feeds_on_channel_id_and_created_at)")
        .where(:channel_id => @channel.id, :created_at => @date_range)
    end

    # apply filters and load the feeds
    @feeds = @feeds.select(@feed_select_options)
      .order('created_at desc')
      .limit(@limit)
      .load

    # sort properly
    @feeds.reverse!

    # calculate feeds
    @feeds = calculate_feeds(@feeds)
  end

  # gets daily feeds
  def get_daily_feeds
    sql_date_range = (@daily_date_range.first + 1.day)..(@daily_date_range.last + 1.day)
    # if this is for a specific field
    if @options[:field_id].present?
      @daily_feeds = DailyFeed.where(:channel_id => @channel.id, :calculation => @calculation_type, :date => sql_date_range, :field => @options[:field_id]).order('date desc').load
    # else get daily feeds for all fields
    else
      @daily_feeds = DailyFeed.where(:channel_id => @channel.id, :calculation => @calculation_type, :date => sql_date_range).order('date desc').load
    end

    # normalize if there are daily feeds
    @daily_feeds = Feed.normalize_feeds(@daily_feeds) if @daily_feeds.present?

    # get dates that are missing from daily feed
    add_missing_daily_feeds

    # add todays data
    add_daily_feed_for_today

    # sort correctly
    @daily_feeds.sort!{ |x, y| x.created_at <=> y.created_at }
  end

  # add feed data for today
  def add_daily_feed_for_today
    @daily_feeds << get_feed_data_for_date(Time.now.to_date) if @options[:days].present?
  end

  # get dates that are missing from daily feed
  def add_missing_daily_feeds
    missing_dates = []
    current_date = @daily_date_range.first + 1.day
    # if current date is older than channel date, set it to channel date
    current_date = @channel.created_at.to_date if @date_range.first < @channel.created_at
    end_date = @daily_date_range.last

    # get dates that exist in daily feeds
    daily_feed_dates = {}
    @daily_feeds.each { |feed| daily_feed_dates[feed.created_at.to_date] = true }

    # iterate through each date
    while current_date < end_date
      # add missing dates
      missing_dates << current_date if daily_feed_dates[current_date] != true
      # go to the next day
      current_date += 1.day
    end

    # add daily feeds for any missing days
    missing_dates.each { |date| add_daily_feed_for_date(date) }
  end

  # apply rounding and min/max
  def format_output_feeds
    # set output feeds
    @output_feeds = (@daily_feeds.present? ? @daily_feeds : @feeds)

    # only get feeds that match min and max values
    @output_feeds = @output_feeds.select{ |x| x.greater_than?(@options[:min]) } if @options[:min].present?
    @output_feeds = @output_feeds.select{ |x| x.less_than?(@options[:max]) } if @options[:max].present?

    # round feeds if necessary
    @output_feeds = object_round(@output_feeds, @options[:round].to_i) if @options[:round] && !@rounded
  end

  # calculate feeds
  def calculate_feeds(feeds)
    # if a feed has data
    if feeds.present?
      # convert to timescales if necessary
      if timeparam_valid?(@options[:timescale])
        feeds = feeds_into_timescales(feeds, @options)
        # convert to sums if necessary
      elsif timeparam_valid?(@options[:sum])
        feeds = feeds_into_sums(feeds, @options)
        @rounded = true
        # convert to averages if necessary
      elsif timeparam_valid?(@options[:average])
        feeds = feeds_into_averages(feeds, @options)
        @rounded = true
        # convert to medians if necessary
      elsif timeparam_valid?(@options[:median])
        feeds = feeds_into_medians(feeds, @options)
        @rounded = true
      end
    end

    return feeds
  end

end

