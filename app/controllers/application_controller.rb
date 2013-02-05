class ApplicationController < ActionController::Base
	# include all helpers for controllers
  helper :all
	# include these helper methods for views
  helper_method :current_user_session, :current_user, :get_header_value
  protect_from_forgery
	before_filter :set_variables

	# set up some variables across the entire application
  def set_variables
    @locale ||= get_locale
    I18n.locale = ALLOWED_LOCALES.include?(@locale) ? @locale : I18n.default_locale
    # sets timezone for current user, all DateTime outputs will be automatically formatted
    Time.zone = current_user.time_zone if current_user
  end
  
  # get the locale, but don't fail if header value doesn't exist
  def get_locale
    locale = get_header_value('HTTP_ACCEPT_LANGUAGE')
    # only look for 'pt-br' as first 5 letters, can make more robust in future if other languages are needed
    locale = locale[0..4].downcase if locale
    return locale
  end

  private

		def set_channels_menu
			@menu = 'channels'
		end

    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end
    
    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.record
    end
    
		# check that user is logged in
		def require_user
			if current_user.nil?
				redirect_to login_path
				false
			end
		end
 
    def require_no_user
      if current_user
        store_location
        redirect_to account_path
        false
      end
    end

    def store_location
			if params[:controller] != "user_sessions"
      	session[:return_to] = request.fullpath
			end
    end
    
    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end

		def domain
			u = request.url
			begin
				# the number 12 is the position at which to begin searching for '/', so we don't get the intitial '/' from http://
				u = u[0..u.index('/', 12)]
			rescue
				u += '/'
			end
			# uncomment the line below for https support in a production environment
			#u = u.sub(/http:/, 'https:') if Rails.env == 'production'
			return u
		end

		# gets the api key
		def get_userkey
			return get_header_value('THINGSPEAKAPIKEY') || params[:key] || params[:api_key] || params[:apikey] 
		end

		# get specified header value
		def get_header_value(name)
			value = nil
			for header in request.env
				value = header[1] if (header[0].upcase.index(name.upcase))
			end
			return value
  	end

    # gets the same data for showing or editing
    def get_channel_data
      @channel = current_user.channels.find(params[:channel_id]) if params[:channel_id]
      @channel = current_user.channels.find(params[:id]) if @channel.nil? and params[:id]
      @key = @channel.api_keys.write_keys.first.try(:api_key) || ""
    end

		def check_permissions(channel)
			render :text => t(:channel_permission) and return if (current_user.nil? || (channel.user_id != current_user.id))
		end

		# checks permission for channel using api_key
		def channel_permission?(channel, api_key)
			if channel.public_flag or (api_key and api_key.channel_id == channel.id) or (current_user and channel.user_id == current_user.id)
				return true
			else
				return false
			end
		end

		# outputs error for bad channel
		def bad_channel_xml
			channel_unauthorized = Channel.new
			channel_unauthorized.id = -1
			return channel_unauthorized.to_xml(:only => :id)
		end

		# outputs error for bad feed
		def bad_feed_xml
			feed_unauthorized = Feed.new
			feedl_unauthorized.id = -1
			return feed_unauthorized.to_xml(:only => :entry_id)
		end

		# options: days = how many days ago, start = start date, end = end date, offset = timezone offset
		def get_date_range(params)
			# set timezone correctly
			set_time_zone(params)

			# if results are specified without start or days parameters, allow start date to be larger
			get_old_data = (params[:results] && params[:start].blank? and params[:days].blank?) ? true : false

			start_date = (get_old_data) ? (Time.now - 1.year) : (Time.now - 1.day)
			end_date = Time.now
			start_date = (Time.now - params[:days].to_i.days) if params[:days]
			start_date = DateTime.strptime(params[:start]) if params[:start]
			end_date = DateTime.strptime(params[:end]) if params[:end]
			date_range = (start_date..end_date)
			# only get a maximum of 30 days worth of data
			date_range = (end_date - 30.days..end_date) if ((end_date - start_date) > 30.days and !get_old_data)

			return date_range
		end


		def is_a_number?(s)
			s.to_s.gsub(/,/, '.').match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
		end

		def set_time_zone(params)
			# set timezone correctly
			if params[:offset]
        # check for 0 offset first since it's the most common
        if params[:offset] == '0'
          Time.zone = 'UTC'
        else
				  Time.zone = set_timezone_from_offset(params[:offset])
        end
			elsif current_user
				Time.zone = current_user.time_zone
			else
				Time.zone = 'UTC'
			end
		end

    # use the offset to find an appropriate timezone
    def set_timezone_from_offset(offset)
      offset = offset.to_i
      # keep track of whether a match was found
      found = false
  
      # loop through each timezone
      ActiveSupport::TimeZone.zones_map.each do |z|
        # set time zone
        Time.zone = z[0]
        timestring = Time.zone.now.to_s
  
        # if time zone matches the offset, leave it as the current timezone
        if (timestring.slice(-5..-3).to_i == offset and timestring.slice(-2..-1).to_i == 0)
          found = true
          break
        end
      end
  
      # if no time zone found, set to utc
      Time.zone = 'UTC' if !found
  
      return Time.zone
    end

end
