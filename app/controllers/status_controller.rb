class StatusController < ApplicationController
  require 'csv'
  layout false

  def recent
    logger.info "Domain is #{@domain}"
    channel = Channel.find(params[:channel_id])
    @channel_id = channel.id
    if channel.public_flag || (current_user && current_user.id == channel.user_id)
      @statuses = channel.recent_statuses
      respond_to do |format|
        format.html { render :partial => 'status/recent' }
        format.json { render :json => @statuses}
      end
    else
      respond_to do |format|
        format.json { render :json => 'Status are not public' }
        format.html { render :text => 'Sorry the statuses are not public' }
      end
    end

  end


  def index
    @channel = Channel.find(params[:channel_id])
    @api_key = ApiKey.find_by_api_key(get_apikey)
    @success = channel_permission?(@channel, @api_key)

    # check for access
    if @success
      # create options hash
      channel_options = { :only => channel_select_terse(@channel) }

      # display only 1 day by default
      params[:days] = 1 if !params[:days]

      # set limits
      limit = (request.format == 'csv') ? 1000000 : 8000
      limit = params[:results].to_i if (params[:results] and params[:results].to_i < 8000)

      # get feed based on conditions
      @feeds = @channel.feeds
        .where(:created_at => get_date_range(params))
        .select([:created_at, :entry_id, :status])
        .order('created_at desc')
        .limit(limit)

      # sort properly
      @feeds.reverse!

      # set output correctly
      if request.format == 'xml'
        @channel_output = @channel.to_xml(channel_options).sub('</channel>', '').strip
        @feed_output = @feeds.to_xml(:skip_instruct => true).gsub(/\n/, "\n  ").chop.chop
      elsif request.format == 'csv'
        @csv_headers = [:created_at, :entry_id, :status]
        @feed_output = @feeds
      else
        @channel_output = @channel.to_json(channel_options).chop
        @feed_output = @feeds.to_json
      end
    # else set error code
    else
      if params[:format] == 'xml'
        @channel_output = bad_channel_xml
      else
        @channel_output = '-1'.to_json

      end
    end

    # set callback for jsonp
    @callback = params[:callback] if params[:callback]

    # output data in proper format
    respond_to do |format|

      format.html { render :template => 'feed/index' }
      format.json { render :template => 'feed/index' }
      format.xml  { render :template => 'feed/index' }
      format.csv  { render :template => 'feed/index' }

    end
  end

  def show
    @channel = Channel.find(params[:channel_id])
    @api_key = ApiKey.find_by_api_key(get_apikey)
    output = '-1'

    # get most recent entry if necessary
    params[:id] = @channel.last_entry_id if params[:id] == 'last'

    @feed = @channel.feeds.where(entry_id: params[:id]).select([:created_at, :entry_id, :status]).first

    @success = channel_permission?(@channel, @api_key)

    # check for access
    if @success
      # set output correctly

      if request.format == 'xml'
        output = @feed.to_xml
      elsif request.format == 'csv'
        @csv_headers = [:created_at, :entry_id, :status]
      elsif (request.format == 'txt' or request.format == 'text')
        output = add_prepend_append(@feed.status)
      else
        output = @feed.to_json
      end

    # else set error code
    else
      if request.format == 'xml'
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
      format.csv { render :action => 'feed/show' }

      format.text { render :text => output }
    end
  end

  private

    # only output these fields for channel
    def channel_select_terse(channel)
      only = [:name]
      only += [:latitude] unless channel.latitude.nil?
      only += [:longitude] unless channel.longitude.nil?
      only += [:elevation] unless channel.elevation.nil? or channel.elevation.empty?

      return only
    end


end

