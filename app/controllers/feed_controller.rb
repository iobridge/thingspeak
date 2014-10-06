class FeedController < ApplicationController
  include FeedHelper
  require 'csv'
  layout 'application', :except => [:index, :debug]

  def index
    feed_factory = FeedFactory.new(params)
    channel = feed_factory.channel
    api_key = ApiKey.find_by_api_key(get_apikey)
    @success = channel_permission?(channel, api_key)

    # set callback for jsonp
    @callback = params[:callback] if params[:callback]

    # set csv headers if necessary
    @csv_headers = feed_factory.feed_select_options if params[:format] == 'csv'

    # check for access
    if @success

      if feed_factory.cache_feeds
        # check cache for stored value
        feed_output_cache_key = cache_key('feed_output')
        channel_output_cache_key = cache_key('channel_output')
        @feed_output = Rails.cache.read(feed_output_cache_key)
        @channel_output = Rails.cache.read(channel_output_cache_key)
      end

      # if cache miss, get data
      if @feed_output.nil? or @channel_output.nil?

        # get feeds
        feeds = feed_factory.get_output_feeds

        # set output correctly
        if params[:format] == 'xml'
          @channel_output = channel.to_xml(channel.select_options(params)).sub('</channel>', '').strip
          @feed_output = feeds.to_xml(:skip_instruct => true).gsub(/\n/, "\n  ").chop.chop
        elsif params[:format] == 'csv'
          @feed_output = feeds
        else
          @channel_output = channel.to_json(channel.select_options(params)).chop
          @feed_output = feeds.to_json(:only => feed_factory.feed_select_options)
        end

        if feed_factory.cache_feeds
          # save to cache
          Rails.cache.write(feed_output_cache_key, @feed_output, :expires_in => 5.minutes)
          Rails.cache.write(channel_output_cache_key, @channel_output, :expires_in => 5.minutes)
        end

      end # end if feeds not empty

      # else no access, set error code
    else
      if params[:format] == 'xml'
        @channel_output = bad_channel_xml
      else
        @channel_output = '-1'.to_json
      end
    end

    # output proper http response if error
    render :text => '-1', :status => 400 and return if !@success

    # output data in proper format
    respond_to do |format|
      format.html
      format.json
      format.xml
      format.csv
    end
  end

  def last_sum
    last_method = method('last_group_call')
    last_method.call('sums')
  end

  def last_median
    last_method = method('last_group_call')
    last_method.call('medians')
  end

  def last_average
    last_method = method('last_group_call')
    last_method.call('averages')
  end

  def last_group_call(arg)
    @channel = Channel.find(params[:channel_id])
    @api_key = ApiKey.find_by_api_key(get_apikey)

    # limit for the number of results to get
    limit = 30
    limit = params[:sum].to_i if params[:sum].present?
    limit = params[:median].to_i if params[:median].present?
    limit = params[:average].to_i if params[:average].present?
    # max limit of 100 past results
    limit = 100 if limit > 100

    # get the last (limit) feeds
    last_feeds = Feed.where(:channel_id => @channel.id).limit(limit).order('created_at desc')
    # put feeds in correct order (oldest to most recent)
    last_feeds.reverse!

    # check if the correct param is present by getting the param name from arg, e.g.: 'median' from 'medians'
    correct_params_present = params[arg.chop.to_sym].present?

    feeds_into = self.method("feeds_into_#{arg}")
    feed = feeds_into.call(last_feeds, params).last if last_feeds.length > 0 && correct_params_present
    create_group_result(feed)
  end

  def create_group_result(feed)
    @success = channel_permission?(@channel, @api_key)

    # if a feed needs to be rounded
    if params[:round] && feed.present?
      feed = item_round(feed, params[:round].to_i)
    end

    # check for access
    if @success && feed.present?
      # set output correctly
      if params[:format] == 'xml'
        output = feed.to_xml
      elsif params[:format] == 'csv'
        @csv_headers = Feed.select_options(@channel, params)
      elsif (params[:format] == 'txt' or params[:format] == 'text')
        output = add_prepend_append(feed["field#{params[:field_id]}"])
      else
        output = feed.to_json
      end
      # else set error code
    else
      if params[:format] == 'xml'
        output = bad_feed_xml
      else
        output = '-1'.to_json
      end
    end

    # output data in proper format
    respond_to do |format|
      format.html { render :json => output }
      format.json { render :json => output, :callback => params[:callback] }
      format.xml { render :xml => output }
      format.csv
      format.text { render :text => output }
    end
  end

  def show
    @channel = Channel.find(params[:channel_id])
    @api_key = ApiKey.find_by_api_key(get_apikey)
    output = '-1'

    # make sure field parameter is set correctly, changes "field1" to "1"
    params[:field_id] = params[:field_id].sub('field', '') if params[:field_id].present?

    # if last entry
    if params[:id] == 'last' && params[:field_id].present? && params[:field_id].to_i != 0
      begin
        # add a timeout since this query may be really long if there is a lot of data,
        # but the last instance of the field is very far back
        Timeout.timeout(5, Timeout::Error) do
          # look for a feed where the value isn't null
          @feed = Feed.where(:channel_id => @channel.id)
            .where("field? is not null", params[:field_id].to_i)
            .select(Feed.select_options(@channel, params))
            .order('entry_id desc')
            .first
        end
      rescue Timeout::Error
      rescue
      end
    # else get by entry
    else
      # get most recent entry if necessary
      params[:id] = @channel.last_entry_id if params[:id] == 'last'
      @feed = Feed.where(:channel_id => @channel.id, :entry_id => params[:id]).select(Feed.select_options(@channel, params)).first
    end

    @success = channel_permission?(@channel, @api_key)

    # if a feed needs to be rounded
    if params[:round]
      @feed = item_round(@feed, params[:round].to_i)
    end

    # check for access
    if @success and @feed

      # set output correctly
      if params[:format] == 'xml'
        output = @feed.to_xml
      elsif params[:format] == 'csv'
        @csv_headers = Feed.select_options(@channel, params)
      elsif (params[:format] == 'txt' || params[:format] == 'text' || params[:format] == 'html' || params[:format].blank?)

        # if no field_id, just return the json feed
        if params[:field_id].blank?
          output = @feed.to_json
        # if the field exists
        elsif @feed.attributes.keys.include?("field#{params[:field_id]}")
          output = add_prepend_append(@feed["field#{params[:field_id]}"])
        end

      else
        output = @feed.to_json
      end

    # else set error code
    else
      if params[:format] == 'xml'
        output = bad_feed_xml
      else
        output = '-1'.to_json
      end
    end

    # output data in proper format
    respond_to do |format|
      format.html { render :text => output }
      format.json { render :json => output, :callback => params[:callback] }
      format.xml { render :xml => output }
      format.csv
      format.text { render :text => output }
    end
  end

  def debug
    @time_start = Time.now

    channel = Channel.find(params[:channel_id])
    api_key = ApiKey.find_by_api_key(get_apikey)
    @success = channel_permission?(channel, api_key)

    # create options hash
    select_options = Feed.select_options(channel, params)

    # get feeds
    feeds = Feed.where(channel_id: channel.id, created_at: get_date_range(params)).select(select_options).order('created_at desc')

    @count = feeds.count
    @time_after_db = Time.now

    # sort properly
    feeds.reverse!

    @time_after_sort = Time.now

    @channel_output = channel.to_json(channel.select_options(params)).chop
    @feed_output = feeds.to_json

    @time_after_json = Time.now
  end

end

