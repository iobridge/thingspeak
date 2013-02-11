class FeedController < ApplicationController
	require 'csv'
	layout 'application', :except => :index

	def index
		channel = Channel.find(params[:channel_id])
		api_key = ApiKey.find_by_api_key(get_userkey)
		@success = channel_permission?(channel, api_key)

		# set timezone correctly
		set_time_zone(params)

		# set limits
		limit = params[:results].to_i if params[:results]

		# check for access
		if @success

			# create options hash
			channel_options = { :only => channel_select_data(channel) }
			select_options = feed_select_data(channel)

			# get feed based on conditions
			feeds = Feed.find(
				:all,
				:conditions => { :channel_id => channel.id, :created_at => get_date_range(params) },
				:select => select_options,
				:order => 'created_at desc',
				:limit => limit
			)

      # keep track of whether data has been rounded already
      rounded = false

			# if a feed has data
			if !feeds.empty?
				# convert to timescales if necessary
				if timeparam_valid?(params[:timescale])
					feeds = feeds_into_timescales(feeds)
				# convert to sums if necessary
				elsif timeparam_valid?(params[:sum])
					feeds = feeds_into_sums(feeds)
          rounded = true
				# convert to averages if necessary
				elsif timeparam_valid?(params[:average])
					feeds = feeds_into_averages(feeds)
          rounded = true
				# convert to medians if necessary
				elsif timeparam_valid?(params[:median])
					feeds = feeds_into_medians(feeds)
          rounded = true
				end
			end

      # if a feed needs to be rounded
      if params[:round] and !rounded
        feeds = object_round(feeds, params[:round].to_i)
      end

			# set output correctly
			if params[:format] == 'xml'
				@channel_output = channel.to_xml(channel_options).sub('</channel>', '').strip
				@feed_output = feeds.to_xml(:skip_instruct => true).gsub(/\n/, "\n  ").chop.chop
			elsif params[:format] == 'csv'
				@feed_output = feeds
			else
				@channel_output = channel.to_json(channel_options).chop
				@feed_output = feeds.to_json
			end

		# else no access, set error code
		else
			if params[:format] == 'xml'
				@channel_output = bad_channel_xml
			else
				@channel_output = '-1'.to_json
			end
		end

		# set callback for jsonp
		@callback = params[:callback] if params[:callback]

		# set csv headers if necessary
		@csv_headers = select_options if params[:format] == 'csv'

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

	def show
		@channel = Channel.find(params[:channel_id])
		@api_key = ApiKey.find_by_api_key(get_userkey)
		output = '-1'

		# get most recent entry if necessary
		params[:id] = @channel.last_entry_id if params[:id] == 'last'

		# set timezone correctly
		set_time_zone(params)

		@feed = Feed.find(
			:first,
			:conditions => { :channel_id => @channel.id, :entry_id => params[:id] },
			:select => feed_select_data(@channel)
		)
		@success = channel_permission?(@channel, @api_key)

    # if a feed needs to be rounded
    if params[:round]
      @feed = item_round(@feed, params[:round].to_i)
    end

		# check for access
		if @success
			# set output correctly
			if params[:format] == 'xml'
				output = @feed.to_xml
			elsif params[:format] == 'csv'
				@csv_headers = feed_select_data(@channel)
			elsif (params[:format] == 'txt' or params[:format] == 'text')
				output = add_prepend_append(@feed["field#{params[:field_id]}"])
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
			format.csv
			format.text { render :text => output }
		end
	end

	private

		# only output these fields for channel
		def channel_select_data(channel)
			only = [:name, :created_at, :updated_at, :id, :last_entry_id]
			only += [:description] unless channel.description.blank?
			only += [:latitude] unless channel.latitude.blank?
			only += [:longitude] unless channel.longitude.blank?
			only += [:elevation] unless channel.elevation.blank?
			only += [:field1] unless channel.field1.blank?
			only += [:field2] unless channel.field2.blank?
			only += [:field3] unless channel.field3.blank?
			only += [:field4] unless channel.field4.blank?
			only += [:field5] unless channel.field5.blank?
			only += [:field6] unless channel.field6.blank?
			only += [:field7] unless channel.field7.blank?
			only += [:field8] unless channel.field8.blank?
	
			return only
		end
	
		# only output these fields for feed
		def feed_select_data(channel)
			only = [:created_at]
			only += [:entry_id] unless timeparam_valid?(params[:timescale]) or timeparam_valid?(params[:average]) or timeparam_valid?(params[:median]) or timeparam_valid?(params[:sum])
			only += [:field1] unless channel.field1.blank? or (params[:field_id] and params[:field_id] != '1')
			only += [:field2] unless channel.field2.blank? or (params[:field_id] and params[:field_id] != '2')
			only += [:field3] unless channel.field3.blank? or (params[:field_id] and params[:field_id] != '3')
			only += [:field4] unless channel.field4.blank? or (params[:field_id] and params[:field_id] != '4')
			only += [:field5] unless channel.field5.blank? or (params[:field_id] and params[:field_id] != '5')
			only += [:field6] unless channel.field6.blank? or (params[:field_id] and params[:field_id] != '6')
			only += [:field7] unless channel.field7.blank? or (params[:field_id] and params[:field_id] != '7')
			only += [:field8] unless channel.field8.blank? or (params[:field_id] and params[:field_id] != '8')

			# add geolocation data if necessary
			if params[:location] and params[:location].upcase == 'TRUE'
				only += [:latitude]
				only += [:longitude]
				only += [:elevation]
			end
	
			# add status if necessary
			only += [:status] if params[:status] and params[:status].upcase == 'TRUE'

			return only
		end

		# checks for valid timescale
		def timeparam_valid?(timeparam)
			valid_minutes = [10, 15, 20, 30, 60, 240, 720, 1440]
			if timeparam and valid_minutes.include?(timeparam.to_i)
				return true
			else
				return false
			end
		end

    # applies rounding to an enumerable object
    def object_round(object, round=nil, match='field')
      object.each_with_index do |o, index|
        object[index] = item_round(o, round, match)
      end

      return object
    end

    # applies rounding to a single item's attributes if necessary
    def item_round(item, round=nil, match='field')
      # for each attribute
      item.attribute_names.each do |attr|
        # only add non-null numeric fields
        if attr.index(match) and !item[attr].nil? and is_a_number?(item[attr])
          # keep track of whether the value contains commas
          comma_flag = (item[attr].to_s.index(',')) ? true : false

          # replace commas with decimals if appropriate
          item[attr] = item[attr].to_s.gsub(/,/, '.') if comma_flag

          # do the actual rounding
		      item[attr] = sprintf "%.#{round}f", item[attr]

          # replace decimals with commas if appropriate
          item[attr] = item[attr].to_s.gsub(/\./, ',') if comma_flag
        end
      end

      # output new item
      return item
    end

		# slice feed into timescales
		def feeds_into_timescales(feeds)
			# convert timescale (minutes) into seconds
			seconds = params[:timescale].to_i * 60
			# get floored time ranges
			start_time = get_floored_time(feeds.first.created_at, seconds)
			end_time = get_floored_time(feeds.last.created_at, seconds)

			# create empty array with appropriate size
			timeslices = Array.new((((end_time - start_time) / seconds).abs).floor)


			# create a blank clone of the first feed so that we only get the necessary attributes
			empty_feed = create_empty_clone(feeds.first)

			# add feeds to array
			feeds.each do |f|
				i = ((f.created_at - start_time) / seconds).floor
				f.created_at = start_time + i * seconds
				timeslices[i] = f if timeslices[i].nil?
			end

			# fill in empty array elements
			timeslices.each_index do |i|
				if timeslices[i].nil?
					current_feed = empty_feed.clone
					current_feed.created_at = (start_time + (i * seconds))
					timeslices[i] = current_feed
				end
			end

			return timeslices
		end

		# slice feed into averages
		def feeds_into_averages(feeds)
			# convert timescale (minutes) into seconds
			seconds = params[:average].to_i * 60
			# get floored time ranges
			start_time = get_floored_time(feeds.first.created_at, seconds)
			end_time = get_floored_time(feeds.last.created_at, seconds)

			# create empty array with appropriate size
			timeslices = Array.new(((end_time - start_time) / seconds).floor)

			# create a blank clone of the first feed so that we only get the necessary attributes
			empty_feed = create_empty_clone(feeds.first)

			# add feeds to array
			feeds.each do |f|
				i = ((f.created_at - start_time) / seconds).floor
				f.created_at = start_time + i * seconds
				# create multidimensional array
				timeslices[i] = [] if timeslices[i].nil?
				timeslices[i].push(f)
			end		

			# keep track of whether numbers use commas as decimals
			comma_flag = false

			# fill in array
			timeslices.each_index do |i|
				# insert empty values
				if timeslices[i].nil?
					current_feed = empty_feed.clone
					current_feed.created_at = (start_time + (i * seconds))
					timeslices[i] = current_feed
				# else average the inner array
				else
					sum_feed = empty_feed.clone
					sum_feed.created_at = timeslices[i].first.created_at
					# for each feed
					timeslices[i].each do |f|
						# for each attribute, add to sum_feed so that we have the total
						sum_feed.attribute_names.each do |attr|

							# only add non-null integer fields
							if attr.index('field') and !f[attr].nil? and is_a_number?(f[attr])
								# set comma_flag once if we find a number with a comma
								comma_flag = true if !comma_flag and f[attr].to_s.index(',')

								# set initial data
								if sum_feed[attr].nil?
									sum_feed[attr] = parsefloat(f[attr])
								# add data
								elsif f[attr]
									sum_feed[attr] = parsefloat(sum_feed[attr]) + parsefloat(f[attr])
								end
							end

						end
					end

					# set to the averaged feed
					timeslices[i] = object_average(sum_feed, timeslices[i].length, comma_flag, params[:round])
				end
			end

			return timeslices
		end

		# slice feed into medians
		def feeds_into_medians(feeds)
			# convert timescale (minutes) into seconds
			seconds = params[:median].to_i * 60
			# get floored time ranges
			start_time = get_floored_time(feeds.first.created_at, seconds)
			end_time = get_floored_time(feeds.last.created_at, seconds)

			# create empty array with appropriate size
			timeslices = Array.new(((end_time - start_time) / seconds).floor)

			# create a blank clone of the first feed so that we only get the necessary attributes
			empty_feed = create_empty_clone(feeds.first)

			# add feeds to array
			feeds.each do |f|
				i = ((f.created_at - start_time) / seconds).floor
				f.created_at = start_time + i * seconds
				# create multidimensional array
				timeslices[i] = [] if timeslices[i].nil?
				timeslices[i].push(f)
			end		

			# keep track of whether numbers use commas as decimals
			comma_flag = false

			# fill in array
			timeslices.each_index do |i|
				# insert empty values
				if timeslices[i].nil?
					current_feed = empty_feed.clone
					current_feed.created_at = (start_time + (i * seconds))
					timeslices[i] = current_feed
				# else get median values for the inner array
				else

					# create blank hash called 'fields' to hold data
					fields = {}

					# for each feed
					timeslices[i].each do |f|

						# for each attribute
						f.attribute_names.each do |attr|
							if attr.index('field')

								# create blank array for each field
								fields["#{attr}"] = [] if fields["#{attr}"].nil?

								# push numeric field data onto its array
								if is_a_number?(f[attr])
									# set comma_flag once if we find a number with a comma
									comma_flag = true if !comma_flag and f[attr].to_s.index(',')

									fields["#{attr}"].push(parsefloat(f[attr]))
								end

							end
						end

					end

					# sort fields arrays
					fields.each_key do |key|
						fields[key] = fields[key].compact.sort
					end

					# get the median
					median_feed = empty_feed.clone
					median_feed.created_at = timeslices[i].first.created_at
					median_feed.attribute_names.each do |attr|
						median_feed[attr] = object_median(fields[attr], comma_flag, params[:round]) if attr.index('field')
					end

					timeslices[i] = median_feed

				end
			end

			return timeslices
		end

		# slice feed into sums
		def feeds_into_sums(feeds)
			# convert timescale (minutes) into seconds
			seconds = params[:sum].to_i * 60
			# get floored time ranges
			start_time = get_floored_time(feeds.first.created_at, seconds)
			end_time = get_floored_time(feeds.last.created_at, seconds)

			# create empty array with appropriate size
			timeslices = Array.new(((end_time - start_time) / seconds).floor)

			# create a blank clone of the first feed so that we only get the necessary attributes
			empty_feed = create_empty_clone(feeds.first)

			# add feeds to array
			feeds.each do |f|
				i = ((f.created_at - start_time) / seconds).floor
				f.created_at = start_time + i * seconds
				# create multidimensional array
				timeslices[i] = [] if timeslices[i].nil?
				timeslices[i].push(f)
			end		

			# keep track of whether numbers use commas as decimals
			comma_flag = false

			# fill in array
			timeslices.each_index do |i|
				# insert empty values
				if timeslices[i].nil?
					current_feed = empty_feed.clone
					current_feed.created_at = (start_time + (i * seconds))
					timeslices[i] = current_feed
				# else sum the inner array
				else
					sum_feed = empty_feed.clone
					sum_feed.created_at = timeslices[i].first.created_at
					# for each feed
					timeslices[i].each do |f|
						# for each attribute, add to sum_feed so that we have the total
						sum_feed.attribute_names.each do |attr|
							# only add non-null integer fields
							if attr.index('field') and !f[attr].nil? and is_a_number?(f[attr])

								# set comma_flag once if we find a number with a comma
								comma_flag = true if !comma_flag and f[attr].to_s.index(',')

								# set initial data
								if sum_feed[attr].nil?
									sum_feed[attr] = parsefloat(f[attr])
								# add data
								elsif f[attr]
									sum_feed[attr] = parsefloat(sum_feed[attr]) + parsefloat(f[attr])
								end

							end
						end
					end

					# set to the summed feed
					timeslices[i] = object_sum(sum_feed, comma_flag, params[:round])
				end
			end

			return timeslices
		end

		def is_a_number?(s)
			s.to_s.gsub(/,/, '.').match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
		end

		def parsefloat(number)
			return number.to_s.gsub(/,/, '.').to_f
		end

		# gets the median for an object
		def object_median(object, comma_flag=false, round=nil)
			return nil if object.nil?
			length = object.length
			return nil if length == 0
			output = ''

			# do the calculation
			if length % 2 == 0
				output = (object[(length - 1) / 2] + object[length / 2]) / 2
			else
				output = object[(length - 1) / 2]
			end

			output = sprintf "%.#{round}f", output if round and is_a_number?(output)

			# replace decimals with commas if appropriate
			output = output.to_s.gsub(/\./, ',') if comma_flag

			return output.to_s
		end

		# averages a summed object over length
		def object_average(object, length, comma_flag=false, round=nil)
			object.attribute_names.each do |attr|
				# only average non-null integer fields
				if !object[attr].nil? and is_a_number?(object[attr])
					if round
						object[attr] = sprintf "%.#{round}f", (parsefloat(object[attr]) / length)
					else
						object[attr] = (parsefloat(object[attr]) / length).to_s
					end
					# replace decimals with commas if appropriate
					object[attr] = object[attr].gsub(/\./, ',') if comma_flag
				end
			end

			return object
		end

		# formats a summed object correctly
		def object_sum(object, comma_flag=false, round=nil)
			object.attribute_names.each do |attr|
				# only average non-null integer fields
				if !object[attr].nil? and is_a_number?(object[attr])
					if round
						object[attr] = sprintf "%.#{round}f", parsefloat(object[attr])
					else
						object[attr] = parsefloat(object[attr]).to_s
					end
					# replace decimals with commas if appropriate
					object[attr] = object[attr].gsub(/\./, ',') if comma_flag
				end
			end

			return object
		end

		# creates an empty clone of an object
		def create_empty_clone(object)
			empty_clone = object.dup
			empty_clone.attribute_names.each { |attr| empty_clone[attr] = nil }
			return empty_clone
		end

		# gets time floored to proper interval
		def get_floored_time(input_time, seconds)
 			return Time.zone.at((input_time.to_f / seconds).floor * seconds)
		end

end
