class ChannelsController < ApplicationController
	before_filter :require_user, :except => [ :show, :post_data ]
	before_filter :set_channels_menu
	protect_from_forgery :except => :post_data

	def index
		@channels = current_user.channels
	end

	def show
		@channel = Channel.find(params[:id]) if params[:id]

		# if owner of channel
		get_channel_data if current_user and @channel.user_id == current_user.id
	end

	def edit
		get_channel_data
	end

	def update
		@channel = Channel.find(params[:id])
		# make sure channel belongs to current user
		check_permissions(@channel)
		# protect against bots
		render :text => '' and return if params[:userlogin].length > 0

		@channel.update_attributes(params[:channel])
		@channel.name = "#{t(:channel_default_name)} #{@channel.id}" if params[:channel][:name].empty?
		@channel.save
		redirect_to channel_path(@channel.id) and return
	end

	def create
		# protect against bots
		render :text => '' and return if params[:userlogin].length > 0

		# get default name for field
		@d = t(:channel_default_field)

		# add channel with defaults
		@channel = Channel.new(:field1 => "#{@d}1")
		@channel.user_id = current_user.id
		@channel.save
		
		# now that the channel is saved, we can create the default name
		@channel.name = "#{t(:channel_default_name)} #{@channel.id}"
		@channel.save

		# create an api key for this channel
		@api_key = ApiKey.new
		@api_key.channel_id = @channel.id
		@api_key.user_id = current_user.id
		@api_key.write_flag = 1
		@api_key.api_key = generate_api_key
		@api_key.save

		# redirect to edit the newly created channel
		redirect_to edit_channel_path(@channel.id)
	end

	def destroy
		@channel = Channel.find(params[:id])
		# make sure channel belongs to current user
		check_permissions(@channel)
		
		# do the delete
		@channel.delete
		redirect_to channels_path
	end

	# response is '0' if failure, 'entry_id' if success
	def post_data
		status = '0'
		feed = Feed.new

		api_key = ApiKey.find_by_api_key(get_userkey)

		# if write persmission, allow post
		if (api_key && api_key.write_flag)
			channel = Channel.find(api_key.channel_id)

			# update entry_id for channel and feed
			entry_id = channel.last_entry_id.nil? ? 1 : channel.last_entry_id + 1
			channel.last_entry_id = entry_id
			feed.entry_id = entry_id

			# try to get created_at datetime if appropriate
			if params[:created_at]
				begin
					@feed.created_at = DateTime.parse(params[:created_at])
				# if invalid datetime, don't do anything--rails will set created_at
				rescue
				end
			end
		
			# strip line feeds from end of parameters
			params.each do |key, value|
				params[key] = value.sub(/\\n$/, '').sub(/\\r$/, '')
			end
	
			# set feed details
			feed.channel_id = channel.id
			feed.raw_data = params
			feed.field1 = params[:field1] if params[:field1]
			feed.field2 = params[:field2] if params[:field2]
			feed.field3 = params[:field3] if params[:field3]
			feed.field4 = params[:field4] if params[:field4]
			feed.field5 = params[:field5] if params[:field5]
			feed.field6 = params[:field6] if params[:field6]
			feed.field7 = params[:field7] if params[:field7]
			feed.field8 = params[:field8] if params[:field8]
			feed.status = params[:status] if params[:status]

			if channel.save && feed.save
				status = entry_id
			end
		end
	
		# output response code
		render :text => '0', :status => 400 and return if status == '0'
		render :text => status
	end

end
