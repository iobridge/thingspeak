class ChannelsController < ApplicationController
	before_filter :require_user, :except => [ :show, :post_data ]
	before_filter :set_channels_menu
	protect_from_forgery :except => :post_data
	require 'csv'

	def index
		@channels = current_user.channels
	end

	def show
		@channel = Channel.find(params[:id]) if params[:id]
		@domain = domain

		# if owner of channel
		get_channel_data if current_user and @channel.user_id == current_user.id
	end

	def edit
		get_channel_data
	end

	def update
		@channel = current_user.channels.find(params[:id])
		@channel.update_attributes(params[:channel])

		redirect_to channel_path(@channel.id)
	end

  def create
    channel = current_user.channels.create(:field1 => "#{t(:channel_default_field)} 1")
    channel.add_write_api_key
   
    # redirect to edit the newly created channel 
    redirect_to edit_channel_path(channel)
  end

  # clear all data from a channel
  def clear
    channel = current_user.channels.find(params[:id])
    channel.delete_feeds
    channel.update_attribute(:last_entry_id, nil)

    redirect_to channels_path
	end

	def destroy
		channel = current_user.channels.find(params[:id])
		channel.destroy

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
					feed.created_at = DateTime.parse(params[:created_at])
				# if invalid datetime, don't do anything--rails will set created_at
				rescue
				end
			end
		
			# modify parameters
			params.each do |key, value|
				# strip line feeds from end of parameters
				params[key] = value.sub(/\\n$/, '').sub(/\\r$/, '') if value
				# use ip address if found
				params[key] = request.remote_addr if value.upcase == 'IP_ADDRESS'
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
			feed.latitude = params[:lat] if params[:lat]
			feed.latitude = params[:latitude] if params[:latitude]
			feed.longitude = params[:long] if params[:long]
			feed.longitude = params[:longitude] if params[:longitude]
			feed.elevation = params[:elevation] if params[:elevation]

			if channel.save && feed.save
				status = entry_id
			end
		end
	
		# output response code
		render :text => '0', :status => 400 and return if status == '0'
		render :text => status
	end


	# import view
	def import
		get_channel_data
	end

	# upload csv file to channel
	def upload
		# if no data
		render :text => t(:select_file) and return if params[:upload].blank? or params[:upload][:csv].blank?

		channel = Channel.find(params[:channel_id])
		channel_id = channel.id
		# make sure channel belongs to current user
		check_permissions(channel)
		
		# set time zone
		Time.zone = params[:feed][:time_zone]

		# read data from uploaded file
		csv_array = CSV.parse(params[:upload][:csv].read)

		# does the column have headers
		headers = has_headers?(csv_array)

		# remember the column positions
		entry_id_column = -1
		latitude_column = -1
		longitude_column = -1
		elevation_column = -1
		status_column = -1
		if headers
			csv_array[0].each_with_index do |column, index|
				entry_id_column = index if column.downcase == 'entry_id'
				latitude_column = index if column.downcase == 'latitude'
				longitude_column = index if column.downcase == 'longitude'
				elevation_column = index if column.downcase == 'elevation'
				status_column = index if column.downcase == 'status'
			end
		end

		# delete the first row if it contains headers
		csv_array.delete_at(0) if headers

		# determine if the date can be parsed
		parse_date = date_parsable?(csv_array[0][0])

		# if 2 or more rows
		if !csv_array[1].blank?
			date1 = parse_date ? Time.parse(csv_array[0][0]) : Time.at(csv_array[0][0])
			date2 = parse_date ? Time.parse(csv_array[1][0]) : Time.at(csv_array[1][0])

			# reverse the array if 1st date is larger than 2nd date
			csv_array = csv_array.reverse if date1 > date2
		end

		# loop through each row
		csv_array.each do |row|
			# if row isn't blank
			if !row.blank?
				feed = Feed.new
	
				# set location and status then delete the rows
				# these 4 deletes must be performed in the proper (reverse) order
				feed.status = row.delete_at(status_column) if status_column > 0
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
				feed.channel_id = channel_id
				feed.created_at = parse_date ? Time.zone.parse(row[0]) : Time.zone.at(row[0].to_f)
				feed.raw_data = row.to_s
				feed.field1 = row[1]
				feed.field2 = row[2]
				feed.field3 = row[3]
				feed.field4 = row[4]
				feed.field5 = row[5]
				feed.field6 = row[6]
				feed.field7 = row[7]
				feed.field8 = row[8]

				# save channel and feed
				feed.save
				channel.save

			end
		end

		# set the user's time zone back
		set_time_zone(params)

		# redirect 
		redirect_to channel_path(channel.id)
	end


private

	# determine if the date can be parsed
	def date_parsable?(date)
		return !is_a_number?(date)
	end

	# determine if the csv file has headers
	def has_headers?(csv_array)
		headers = false

		# if there are at least 2 rows
		if (csv_array[0] and csv_array[1])
			row0_integers = 0
			row1_integers = 0	
	
			# if first row, first value contains 'create' or 'date', assume it has headers
			if (csv_array[0][0].downcase.include?('create') or csv_array[0][0].downcase.include?('date'))
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