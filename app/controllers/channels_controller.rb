class ChannelsController < ApplicationController
  include ChannelsHelper, ApiKeys
  before_filter :authenticate_via_api_key!, :only => [:index]
  before_filter :require_user, :except => [:realtime, :realtime_update, :show, :post_data, :social_show, :social_feed, :public]
  before_filter :set_channels_menu
  layout 'application', :except => [:social_show, :social_feed]
  protect_from_forgery :except => [:realtime, :realtime_update, :post_data, :create, :destroy, :clear]
  require 'csv'
  require 'will_paginate/array'

  # get list of all realtime channels
  def realtime
    # error if no key
    respond_with_error(:error_auth_required) and return if params[:realtime_key] != REALTIME_DAEMON_KEY
    channels = Channel.where("realtime_io_serial_number IS NOT NULL")
    render :json => channels.to_json(:root => false, :only => [:id, :realtime_io_serial_number])
  end

  # view list of watched channels
  def watched
    @channels = current_user.watched_channels
  end

  # user watches a channel
  def watch
    @watching = Watching.find_by_user_id_and_channel_id(current_user.id, params[:id])

    # add watching
    if params[:flag] == 'true'
      @watching = Watching.new(:user_id => current_user.id, :channel_id => params[:id]) if @watching.nil?
      @watching.save
      # delete watching
    else
      @watching.delete if !@watching.nil?
    end

    render :text => '1'
  end

  # list public channels
  def public
    # error if page 0
    respond_with_error(:error_resource_not_found) and return if params[:page] == '0'

    @domain = domain
    # default blank response
    @channels = Channel.where(:id => 0).paginate :page => params[:page]

    # get channels by ids
    if params[:channel_ids].present?
      @header = t(:selected_channels)
      @channels = Channel.public_viewable.by_array(params[:channel_ids]).order('ranking desc, updated_at DESC').paginate :page => params[:page]
    # get channels that match a user
    elsif params[:username].present?
      @header = "#{t(:user).capitalize}: #{params[:username]}"
      searched_user = User.find_by_login(params[:username])
      @channels = searched_user.channels.public_viewable.active.order('ranking desc, updated_at DESC').paginate :page => params[:page] if searched_user.present?
    # get channels that match a tag
    elsif params[:tag].present?
      @header = "#{t(:tag).capitalize}: #{params[:tag]}"
      @channels = Channel.public_viewable.active.order('ranking desc, updated_at DESC').with_tag(params[:tag]).paginate :page => params[:page]
    # get channels by location
    elsif params[:latitude].present? && params[:longitude].present? && params[:distance].present?
      @header = "#{t(:channels_near)}: [#{params[:latitude]}, #{params[:longitude]}]"
      @channels = Channel.location_search(params).paginate :page => params[:page]
    # normal channel list
    else
      @header = t(:featured_channels)
      @channels = Channel.public_viewable.active.order('ranking desc, updated_at DESC').paginate :page => params[:page]
    end

    respond_to do |format|
      format.html
      format.json { render :json => Channel.paginated_hash(@channels).to_json }
      format.xml { render :xml => Channel.paginated_hash(@channels).to_xml(:root => 'response') }
    end
  end

  # widget for social feeds
  def social_feed
    # get domain based on ssl
    @domain = domain((get_header_value('x_ssl') == 'true'))
  end

  # main page for a socialsensornetwork.com project
  def social_show
    @channel = Channel.find_by_slug(params[:slug])

    # redirect home if wrong slug
    redirect_to '/' and return if @channel.nil?

    api_key = ApiKey.where(channel_id: @channel.id, write_flag: 1).first
    @post_url = "/update?key=#{api_key.api_key}"

    # names of non-blank channel fields
    @fields = []
    @channel.attribute_names.each do |attr|
      @fields.push(attr) if attr.index('field') and !@channel[attr].blank?
    end
  end

  def social_new
    @channel = Channel.new
  end

  def social_create
    @channel = Channel.new(channel_params)

    # check for blank name
    @channel.errors.add(:base, t(:social_channel_error_name_blank)) if @channel.name.blank?

    # check for blank slug
    @channel.errors.add(:base, t(:social_channel_error_slug_blank)) if @channel.slug.blank?

    # check for at least one field
    fields = false
    @channel.attribute_names.each do |attr|
      if (attr.index('field') or attr.index('status')) and !@channel[attr].blank?
        fields = true
        break
      end
    end
    @channel.errors.add(:base, t(:social_channel_error_fields)) if !fields

    # check for existing slug
    if @channel.errors.count == 0
      @channel.errors.add(:base, t(:social_channel_error_slug_exists)) if Channel.find_by_slug(@channel.slug)
    end

    # if there are no errors
    if @channel.errors.count == 0
      @channel.user_id = current_user.id
      @channel.social = true
      @channel.public_flag = true
      @channel.save

      # create an api key for this channel
      channel.add_write_api_key

      redirect_to channels_path
    else
      render :action => :social_new
    end

  end

  def index
    @channels = current_user.channels
    respond_to do |format|
      format.html
      format.json { render :json => @channels.not_social.to_json(Channel.private_options) }
      format.xml { render :xml => @channel.not_social.to_xml(Channel.private_options) }
    end
  end

  def show
    @channel = Channel.find(params[:id]) if params[:id]

    @title = @channel.name
    @domain = domain
    @mychannel = (current_user && current_user.id == @channel.user_id)
    @width = Chart.default_width
    @height = Chart.default_height

    api_index @channel.id
    # if owner of channel
    get_channel_data if @mychannel

    # if a json or xml request
    if request.format == :json || request.format == :xml
      # authenticate the channel if the user owns the channel
      authenticated = (@mychannel) || (User.find_by_api_key(get_apikey) == @channel.user)
      # set options correctly
      options = authenticated ? Channel.private_options : Channel.public_options
    end

    respond_to do |format|
      format.html do
        if @mychannel
          render "private_show"
          session[:errors] = nil
        else
          render "public_show"
          session[:errors] = nil
        end
      end
      format.json { render :json => @channel.as_json(options) }
      format.xml { render :xml => @channel.to_xml(options) }
    end
  end

  def edit
    get_channel_data
  end

  def update
    # get the current user or find the user via their api key
    @user = current_user || User.find_by_api_key(get_apikey)
    @channel = @user.channels.find(params[:id])

    # make updating attributes easier for updates via api
    params[:channel] = params if params[:channel].blank?

    if params["channel"]["video_type"].blank? && !params["channel"]["video_id"].blank?
      @channel.errors.add(:base, t(:channel_video_type_blank))
    end

    if @channel.errors.count <= 0
      @channel.save_tags(params[:tags][:name]) if params[:tags].present?
      @channel.assign_attributes(channel_params)
      @channel.set_windows
      @channel.save
      @channel.set_ranking
    else
      session[:errors] = @channel.errors
      redirect_to channel_path(@channel.id, :anchor => "channelsettings") and return
    end

    flash[:notice] = t(:channel_update_success)
    respond_to do |format|
      format.json { render :json => @channel.to_json(Channel.private_options) }
      format.xml { render :xml => @channel.to_xml(Channel.private_options) }
      format.any { redirect_to channel_path(@channel.id) }
    end
  end

  def create
    # get the current user or find the user via their api key
    @user = current_user || User.find_by_api_key(get_apikey)
    channel = @user.channels.create(:field1 => "#{t(:channel_default_field)} 1")

    # make updating attributes easier
    params[:channel] = params
    channel.update_attributes(channel_params)

    channel.set_windows(true)
    channel.save
    channel.save_tags(params[:channel][:tags]) if params[:channel][:tags].present?
    channel.add_write_api_key
    channel.set_ranking
    @channel_id = channel.id
    respond_to do |format|
      format.json { render :json => channel.to_json(Channel.private_options) }
      format.xml { render :xml => channel.to_xml(Channel.private_options) }
      format.any { redirect_to channel_path(@channel_id, :anchor => "channelsettings") }
    end
  end

  # clear all data from a channel
  def clear
    # get the current user or find the user via their api key
    @user = current_user || User.find_by_api_key(get_apikey)
    channel = @user.channels.find(params[:id])
    channel.delete_feeds
    respond_to do |format|
      format.json { render :json => [] }
      format.xml { render :xml => [] }
      format.any { redirect_to channel_path(channel.id) }
    end
  end

  def destroy
    # get the current user or find the user via their api key
    @user = current_user || User.find_by_api_key(get_apikey)
    @channel = @user.channels.find(params[:id])
    @channel.destroy
    respond_to do |format|
      format.json { render :json => @channel.to_json(Channel.public_options) }
      format.xml { render :xml => @channel.to_xml(Channel.public_options) }
      format.any { redirect_to channels_path, :status => 303 }
    end
  end

  # post from realtime.io daemon
  def realtime_update
    # exit if not authenticated
    respond_with_error(:error_auth_required) and return if params[:realtime_key] != REALTIME_DAEMON_KEY

    # set feed and channel
    feed = Feed.new
    channel = Channel.find(params[:id])

    # update entry_id for channel and feed
    entry_id = channel.next_entry_id
    channel.last_entry_id = entry_id
    feed.entry_id = entry_id
    # set user agent
    channel.user_agent = 'realtime.io'

    # set feed details
    feed.channel_id = channel.id
    feed.status = params[:status]

    # save channel and feed
    channel.save
    feed.save

    render :nothing => true
  end

  # response is '0' if failure, 'entry_id' if success
  def post_data

    status = '0'
    feed = Feed.new

    api_key = ApiKey.find_by_api_key(get_apikey)

    # if write permission, allow post
    if (api_key && api_key.write_flag)
      channel = api_key.channel

      # don't rate limit if tstream parameter is present
      tstream = params[:tstream] || false;

      # don't rate limit if talkback_key parameter is present
      talkback_key = params[:talkback_key] || false;

      # rate limit posts if channel is not social and timespan is smaller than the allowed window
      render :text => '0' and return if (RATE_LIMIT && !tstream && !talkback_key && !channel.social && Time.now < channel.updated_at + RATE_LIMIT_FREQUENCY.to_i.seconds)

      # if social channel, latitude MUST be present
      render :text => '0' and return if (channel.social && params[:latitude].blank?)

      # update entry_id for channel and feed
      entry_id = channel.next_entry_id
      channel.last_entry_id = entry_id
      feed.entry_id = entry_id
      # set user agent
      channel.user_agent = get_header_value('USER_AGENT')

      # try to get created_at datetime if appropriate
      if params[:created_at].present?
        begin
          feed.created_at = ActiveSupport::TimeZone[Time.zone.name].parse(params[:created_at])
          # if invalid datetime, don't do anything--rails will set created_at
        rescue
        end
      end

      # modify parameters
      params.each do |key, value|
        # this fails so much due to encoding problems that we need to ignore errors
        begin
          # strip line feeds from end of parameters
          params[key] = value.sub(/\\n$/, '').sub(/\\r$/, '') if value
          # use ip address if found
          params[key] = get_header_value('X_REAL_IP') if value.try(:upcase) == 'IP_ADDRESS'
        rescue
        end
      end

      # set feed details
      feed.channel_id = channel.id
      feed.field1 = params[:field1] || params['1'] if params[:field1] || params['1']
      feed.field2 = params[:field2] || params['2'] if params[:field2] || params['2']
      feed.field3 = params[:field3] || params['3'] if params[:field3] || params['3']
      feed.field4 = params[:field4] || params['4'] if params[:field4] || params['4']
      feed.field5 = params[:field5] || params['5'] if params[:field5] || params['5']
      feed.field6 = params[:field6] || params['6'] if params[:field6] || params['6']
      feed.field7 = params[:field7] || params['7'] if params[:field7] || params['7']
      feed.field8 = params[:field8] || params['8'] if params[:field8] || params['8']
      feed.status = params[:status] if params[:status]
      feed.latitude = params[:lat] if params[:lat]
      feed.latitude = params[:latitude] if params[:latitude]
      feed.longitude = params[:long] if params[:long]
      feed.longitude = params[:longitude] if params[:longitude]
      feed.elevation = params[:elevation] if params[:elevation]
      feed.location = params[:location] if params[:location]

      # if the saves were successful
      if channel.save && feed.save
        status = entry_id

        # check for tweet
        if params[:twitter] && params[:tweet]
          # check username
          twitter_account = TwitterAccount.find_by_user_id_and_screen_name(api_key.user_id, params[:twitter])
          if twitter_account
            twitter_account.tweet(params[:tweet])
          end
        end
      else
        raise "Channel or Feed didn't save correctly"
      end
    end

    # if there is a talkback to execute
    if params[:talkback_key].present?
      talkback = Talkback.find_by_api_key(params[:talkback_key])
      command = talkback.execute_command! if talkback.present?
    end

    # output response code
    render(:text => '0', :status => 400) and return if status == '0'

    # if there is a talkback_key and a command that was executed
    if params[:talkback_key].present? && command.present?
        respond_to do |format|
          format.html { render :text => command.command_string }
          format.json { render :json => command.to_json }
          format.xml { render :xml => command.to_xml(Command.public_options) }
        end and return
    end

    # if there is a talkback_key but no command
    respond_with_blank and return if params[:talkback_key].present? && command.blank?

    # normal route, respond with the feed
    respond_to do |format|
      format.html { render :text => status }
      format.json { render :json => feed.to_json }
      format.xml { render :xml => feed.to_xml(Feed.public_options) }
      format.any { render :text => status }
    end and return
  end

  # import view
  def import
    get_channel_data
  end

  # upload csv file to channel
  def upload
    channel = Channel.find(params[:id])
    check_permissions(channel)

    # if no data
    if params[:upload].blank? || params[:upload][:csv].blank?
      flash[:alert] = t(:upload_no_file)
      redirect_to channel_path(channel.id, :anchor => "dataimport") and return
    end

    # set time zone
    Time.zone = params[:feed][:time_zone]
    Chronic.time_class = Time.zone

    # make sure uploaded file doesn't cause errors
    csv_array = nil
    flash_alert = nil
    begin
      # read data from uploaded file
      csv_array = CSV.parse(params[:upload][:csv].read)
    rescue CSV::MalformedCSVError
      flash_alert = t(:upload_incorrect_format)
    end

    # if no data read, output error message
    if csv_array.nil? || csv_array.blank?
      flash[:alert] = flash_alert || t(:upload_no_data)
      redirect_to channel_path(channel.id, :anchor => "dataimport") and return
    end

    # does the column have headers
    headers = has_headers?(csv_array)

    # remember the column positions
    entry_id_column = -1
    latitude_column = -1
    longitude_column = -1
    elevation_column = -1
    location_column = -1
    status_column = -1
    field1_column = -1
    field2_column = -1
    field3_column = -1
    field4_column = -1
    field5_column = -1
    field6_column = -1
    field7_column = -1
    field8_column = -1
    if headers
      csv_array[0].each_with_index do |column, index|
        entry_id_column = index if column.downcase == 'entry_id'
        latitude_column = index if column.downcase == 'latitude'
        longitude_column = index if column.downcase == 'longitude'
        elevation_column = index if column.downcase == 'elevation'
        location_column = index if column.downcase == 'location'
        status_column = index if column.downcase == 'status'
        field1_column = index if column.downcase == 'field1'
        field2_column = index if column.downcase == 'field2'
        field3_column = index if column.downcase == 'field3'
        field4_column = index if column.downcase == 'field4'
        field5_column = index if column.downcase == 'field5'
        field6_column = index if column.downcase == 'field6'
        field7_column = index if column.downcase == 'field7'
        field8_column = index if column.downcase == 'field8'
      end
    end

    # delete the first row if it contains headers
    csv_array.delete_at(0) if headers

    # determine if the date can be parsed
    parse_date = date_parsable?(csv_array[0][0]) unless csv_array[0].nil? || csv_array[0][0].nil?

    # if 2 or more rows
    if !csv_array[1].blank?
      date1 = Chronic.parse(csv_array[0][0]) if parse_date
      date2 = Chronic.parse(csv_array[1][0]) if parse_date

      # reverse the array if the dates exist and 1st date is larger than 2nd date
      csv_array = csv_array.reverse if date1.present? && date2.present? && date1 > date2
    end

    # loop through each row
    csv_array.each do |row|
      # if row isn't blank
      if !row.blank?
        feed = Feed.new

        # add the fields if they are from named columns, using reverse order
        feed.field8 = row.delete_at(field8_column) if field8_column != -1
        feed.field7 = row.delete_at(field7_column) if field7_column != -1
        feed.field6 = row.delete_at(field6_column) if field6_column != -1
        feed.field5 = row.delete_at(field5_column) if field5_column != -1
        feed.field4 = row.delete_at(field4_column) if field4_column != -1
        feed.field3 = row.delete_at(field3_column) if field3_column != -1
        feed.field2 = row.delete_at(field2_column) if field2_column != -1
        feed.field1 = row.delete_at(field1_column) if field1_column != -1

        # set location and status then delete the rows
        # these 5 deletes must be performed in the proper (reverse) order
        feed.status = row.delete_at(status_column) if status_column > 0
        feed.location = row.delete_at(location_column) if location_column > 0
        feed.elevation = row.delete_at(elevation_column) if elevation_column > 0
        feed.longitude = row.delete_at(longitude_column) if longitude_column > 0
        feed.latitude = row.delete_at(latitude_column) if latitude_column > 0

        # remove entry_id column if necessary
        row.delete_at(entry_id_column) if entry_id_column > 0

        # update entry_id for channel and feed
        entry_id = channel.last_entry_id.nil? ? 1 : channel.last_entry_id + 1
        channel.last_entry_id = entry_id
        feed.entry_id = entry_id

        # set feed data
        feed.channel_id = channel.id
        feed.created_at = Chronic.parse(row[0]) if parse_date

        # add the fields normally if necessary
        feed.field1 = row[1] if feed.field1.blank?
        feed.field2 = row[2] if feed.field2.blank?
        feed.field3 = row[3] if feed.field3.blank?
        feed.field4 = row[4] if feed.field4.blank?
        feed.field5 = row[5] if feed.field5.blank?
        feed.field6 = row[6] if feed.field6.blank?
        feed.field7 = row[7] if feed.field7.blank?
        feed.field8 = row[8] if feed.field8.blank?

        # save channel and feed
        feed.save
        channel.save

      end
    end

    # redirect
    flash[:notice] = t(:upload_successful)
    redirect_to channel_path(channel.id, :anchor => "dataimport")
  end


  private

    # only allow these params
    def channel_params
      params.require(:channel).permit(:name, :url, :description, :metadata, :latitude, :longitude, :field1, :field2, :field3, :field4, :field5, :field6, :field7, :field8, :elevation, :public_flag, :status, :video_id, :video_type)
    end

    # determine if the date can be parsed
    def date_parsable?(date)
      return !is_a_number?(date)
    end

    # determine if the csv file has headers
    def has_headers?(csv_array)
      headers = false

      # if there are at least 2 rows
      if (csv_array[0].present? && csv_array[1].present?)
        row0_integers = 0
        row1_integers = 0

        # if first row, first value contains 'create' or 'date', assume it has headers
        if (csv_array[0][0].present? && (csv_array[0][0].downcase.include?('create') || csv_array[0][0].downcase.include?('date')))
          headers = true
        else
          # count integers in row0
          csv_array[0].each_with_index do |value, i|
            row0_integers += 1 if is_a_number?(value)
          end

          # count integers in row1
          csv_array[1].each_with_index do |value, i|
            row1_integers += 1 if is_a_number?(value)
          end

          # if row1 has more integers, assume row0 is headers
          headers = true if row1_integers > row0_integers
        end
      end

      return headers
    end

end

