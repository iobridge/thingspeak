class StatusController < ApplicationController
	require 'csv'

	def index
		@channel = Channel.find(params[:channel_id])
		@api_key = ApiKey.find_by_api_key(get_userkey)
		@success = channel_permission?(@channel, @api_key)

		# check for access
		if @success
			# create options hash
			channel_options = { :only => channel_select_terse(@channel) }

			# display only 1 day by default
			params[:days] = 1 if !params[:days]

			# get feed based on conditions
			@feeds = Feed.find(
				:all,
				:conditions => { :channel_id => @channel.id, :created_at => get_date_range(params) },
				:select => [:created_at, :status],
				:order => 'created_at'
			)

			# set output correctly
			if params[:format] == 'xml'
				@channel_xml = @channel.to_xml(channel_options).sub('</channel>', '').strip
				@feed_xml = @feeds.to_xml(:skip_instruct => true).gsub(/\n/, "\n  ").chop.chop
			elsif params[:format] == 'csv'
				@csv_headers = [:created_at, :status]
			else
				@channel_json = @channel.to_json(channel_options).chop
				@feed_json = @feeds.to_json
			end
		# else set error code
		else
			if params[:format] == 'xml'
				@channel_xml = bad_channel_xml
			else
				@channel_json = '-1'.to_json
			end
		end

		# set callback for jsonp
		@callback = params[:callback] if params[:callback]

		# output data in proper format
		respond_to do |format|
			format.html { render :text => @feed_json }
			format.json { render :action => 'feed/index' }
			format.xml { render :action => 'feed/index' }
			format.csv { render :action => 'feed/index' }
		end
	end

	def show
		@channel = Channel.find(params[:channel_id])
		@api_key = ApiKey.find_by_api_key(params[:key])
		output = '-1'

		# get most recent entry if necessary
		params[:id] = @channel.last_entry_id if params[:id] == 'last'

		@feed = Feed.find(
			:first,
			:conditions => { :channel_id => @channel.id, :entry_id => params[:id] },
			:select => [:created_at, :status]
		)
		@success = channel_permission?(@channel, @api_key)

		# check for access
		if @success
			# set output correctly
			if params[:format] == 'xml'
				output = @feed.to_xml
			elsif params[:format] == 'csv'
				@csv_headers = [:created_at, :entry_id, :status]
			elsif (params[:format] == 'txt' or params[:format] == 'text')
				output = add_prepend_append(@feed.status)
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
