class ChartsController < ApplicationController

	def index
		set_channels_menu
		@channel = Channel.find(params[:channel_id])
		@channel_id = params[:channel_id]
		@domain = domain		

		# default chart size
		@width = default_width
		@height = default_height

		check_permissions(@channel)
	end

	def show
		# allow these parameters when creating feed querystring
		feed_params = ['key','days','start','end','round','timescale','average','median','sum']

		# default chart size
		@width = default_width
		@height = default_height

		# add extra parameters to querystring
		@qs = ''
		params.each do |p|
			@qs += "&#{p[0]}=#{p[1]}" if feed_params.include?(p[0])
		end

		# fix chart colors if necessary
		params[:color] = fix_color(params[:color])
		params[:bgcolor] = fix_color(params[:bgcolor])

		@domain = domain
		render :layout => false
	end

	# save chart options
	def update
		@channel = Channel.find(params[:channel_id])
		@status = 0

		# check permissions
		if @channel.user_id == current_user.id

			# save data
			@channel["options#{params[:id]}"] = params[:options]
			if @channel.save
				@status = 1
			end

		end

		# return response: 1=success, 0=failure
		render :json => @status.to_json
	end

	private

		def default_width
			450
		end

		def default_height
			250
		end

		# fixes chart color if user forgets the leading '#'
		def fix_color(color)
			# check for 3 or 6 character hexadecimal value
			if (color and color.match(/^([0-9]|[a-f]|[A-F]){3}(([0-9]|[a-f]|[A-F]){3})?$/))
				color = '#' + color
			end

			return color
		end

end
