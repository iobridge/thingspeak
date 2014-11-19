class ApplicationController < ActionController::Base
  skip_before_filter :verify_authenticity_token
  # include all helpers for controllers
  helper :all
  # include these helper methods for views
  helper_method :current_user_session, :current_user, :logged_in?, :get_header_value, :to_bytes
  protect_from_forgery
  before_filter :allow_cross_domain_access, :set_variables, :set_time_zone
  before_filter :configure_permitted_parameters, if: :devise_controller?
  after_filter :remove_headers
  before_filter :authenticate_user_from_token!

  # responds with blank
  def respond_with_blank
    respond_to do |format|
      format.html { render :text => '' }
      format.json { render :json => {}.to_json }
      # fix xml response line breaks
      format.xml { render :xml => {}.to_xml.gsub("\n", '').gsub("<hash>", "\n<hash>") }
    end
  end

  # responds with an error
  def respond_with_error(error_code)
    error_response = ErrorResponse.new(error_code)
    respond_to do |format|
      format.html { render :text => error_response.error_code, :status => error_response.http_status }
      format.json { render :json => error_response.to_json, :status => error_response.http_status }
      format.xml { render :xml => error_response.to_xml, :status => error_response.http_status }
    end
  end

  # set up some variables across the entire application
  def set_variables
    @api_domain ||= api_domain
    @ssl_api_domain ||= ssl_api_domain
    @locale ||= get_locale
    I18n.locale = @locale

    # allows use of daily params
    params[:timescale] = '1440' if params[:timescale] == 'daily'
    params[:average] = '1440' if params[:average] == 'daily'
    params[:median] = '1440' if params[:median] == 'daily'
    params[:sum] = '1440' if params[:sum] == 'daily'
  end

  # change default devise sign_in page; make admins sign in work correctly
  def after_sign_in_path_for(resource)
    if resource.is_a?(AdminUser)
      admin_dashboard_path
    else
      channels_path
    end
  end

  # authenticates user based on the user's api_key
  def authenticate_via_api_key!
    # exit if no api_key
    return false if params[:api_key].blank?
    # get the user
    user = User.find_by_api_key(params[:api_key])
    # sign in the user if they exist
    sign_in(user, store: false) if user.present?
  end

  # get the locale, but don't fail if header value doesn't exist
  def get_locale
    locale = get_header_value('HTTP_ACCEPT_LANGUAGE')

    if locale and ALLOWED_LOCALES.include?(locale[0..1].downcase)
      locale = locale[0..1].downcase
    elsif locale and ALLOWED_LOCALES.include?(locale[0..4].downcase)
      locale = locale[0..4].downcase
    else
      locale =  I18n.default_locale
    end

    return locale
  end

  protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:login, :email, :password, :password_confirmation, :remember_me) }
      devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:login, :email, :password, :remember_me) }
      devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:login, :email, :password, :password_confirmation, :time_zone, :password_current) }
    end

  private

    # authenticates user based on token from users#api_login
    def authenticate_user_from_token!
      # exit if no login or token
      return false if params[:login].blank? || params[:token].blank?

      # get the user by login or email
      user = User.find_by_login_or_email(params[:login])

      # safe compare, avoids timing attacks
      if user.present? && Devise.secure_compare(user.authentication_token, params[:token])
        sign_in user, store: false
      end
    end

    # remove headers if necessary
    def remove_headers
      response.headers.delete_if {|key| true} if params[:headers] == 'false'
    end

    # allow javascript requests from any domain
    def allow_cross_domain_access
      response.headers['Access-Control-Allow-Origin'] = '*'
      response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, OPTIONS, DELETE, PATCH'
      response.headers['Access-Control-Allow-Headers'] = 'origin, content-type, X-Requested-With'
      response.headers['Access-Control-Max-Age'] = '1800'
    end

    def logged_in?
      true if current_user
    end

    # converts a string to a byte string for c output
    def to_bytes(input, separator='.', prefix='')
      return '' if input == nil
      output = []
      # split the input array using the separator, and add necessary prefixes to each item
      input.split(separator).each { |i| output.push(prefix + i) }
      # rejoin the array into a comma separated string
      return output.join(', ')
    end

    # set menus
    def set_support_menu; @menu = 'support'; end
    def set_channels_menu; @menu = 'channels'; end
    def set_apps_menu; @menu = 'apps'; end
    def set_plugins_menu; @menu = 'plugins'; end
    def set_devices_menu; @menu = 'devices'; end

    def require_user
      logger.info "Require User"
      if current_user.nil? && User.find_by_api_key(get_apikey).nil?
        respond_to do |format|
          format.html   {
            session[:link_back] = request.url
            logger.debug "Redirecting to login"
            redirect_to login_path
            return true
          }
          format.json do
            render :json => {'error' => 'Could not authenticate you.'}, :status => :unauthorized
            return true
          end
        end
        return false
      end
    end

    def require_no_user
      if current_user
        store_location
        redirect_to account_path
        false
      end
    end

    def require_admin
      unless current_admin_user.present?
        render :nothing => true, :status => 403 and return
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

    def domain(ssl=true)
      u = request.url
      begin
        # the number 12 is the position at which to begin searching for '/', so we don't get the intitial '/' from http://
        u = u[0..u.index('/', 12)]
      rescue
        u += '/'
      end
      u = u.sub(/http:/, 'https:') if (Rails.env == 'production' and ssl)
      return u
    end

    def ssl
      (Rails.env == 'production') ? 'https' : 'http'
    end

    # domain for the api
    def api_domain(ssl=false)
      output = (Rails.env == 'production') ? API_DOMAIN : domain
      output = output.sub(/http:/, 'https:') if ssl == true
      return output
    end

    # ssl domain for the api
    def ssl_api_domain; (Rails.env == 'production') ? api_domain.sub('http', 'https'): api_domain; end

    # gets the api key
    def get_apikey
      key = get_header_value(HTTP_HEADER_API_KEY_NAME) || params[:key] || params[:api_key] || params[:apikey]
      key.strip if key.present?
      return key.to_s
    end

    # get specified header value
    def get_header_value(name)
      name.upcase!
      request.env.select {|header| header.upcase.index(name) }.values[0]
    end

    # generates a hash key unique to the user and url
    def cache_key(type)
      cache_key = request.host + request.path
      user_id = current_user ? current_user.id : '0'

      params.each do |key, value|
        # add the parameter if appropriate
        cache_key += "&#{key}=#{value}" if key != 'callback' && key != 'controller' && key != 'action' && key != 'format'
      end

      return "#{user_id}-#{type}-#{cache_key}"
    end

    # reads a file using the relative path to the file
    def read_file(file_path)
      path = file_path[0, file_path.rindex('/')]
      filename = file_path[file_path.rindex('/') + 1, file_path.length]
      output = ''

      File.open("#{File.expand_path(path)}/#{filename}", 'r') do |f|
        while line = f.gets
          output += line
        end
      end

      return output
    end

    # prepends or appends text
    def add_prepend_append(input)
      output = input.to_s
      output = params[:prepend] + output if params[:prepend]
      output += params[:append] if params[:append]
      return output
    end

    # gets the same data for showing or editing
    def get_channel_data
      @channel = current_user.channels.find(params[:channel_id]) if params[:channel_id]
      @channel = current_user.channels.find(params[:id]) if @channel.nil? and params[:id]
      @channel.ranking = @channel.set_ranking if @channel.ranking.blank?
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
      feed_unauthorized.id = -1
      return feed_unauthorized.to_xml(:only => :entry_id)
    end

    # options: days = how many days ago, start = start date, end = end date, offset = timezone offset
    def get_date_range(params)
      # allow more past data if necessary
      get_old_data = (params[:results].present? || params[:start].present? || params[:days].present?) ? true : false

      # set default start and end dates
      start_date = (get_old_data) ? Time.parse('2010-01-01') : (Time.now - 1.day)
      end_date = Time.now

      # set new start and end dates if necessary
      start_date = (Time.now - params[:days].to_i.days) if params[:days].present?
      start_date = (Time.now - params[:minutes].to_i.minutes) if params[:minutes].present?
      start_date = ActiveSupport::TimeZone[Time.zone.name].parse(params[:start]) if params[:start].present?
      end_date = ActiveSupport::TimeZone[Time.zone.name].parse(params[:end]) if params[:end].present?

      # set the date range
      date_range = (start_date..end_date)
      # only get a maximum of 30 days worth of data
      date_range = (end_date - 30.days..end_date) if ((end_date - start_date) > 30.days and !get_old_data)
      return date_range
    end

    # set timezone correctly
    def set_time_zone
      if params[:timezone].present?
        begin
          Time.zone = TZInfo::Timezone.get(params[:timezone])
        rescue
          Time.zone = 'UTC'
        end
      elsif params[:offset].present?
        Time.zone = set_timezone_from_offset(params[:offset])
      elsif current_user.present?
        Time.zone = current_user.time_zone_or_utc
      else
        Time.zone = 'UTC'
      end
    end

    # use the offset to find an appropriate timezone
    def set_timezone_from_offset(offset)
      offset = offset.to_i
      # always set to UTC if offset is 0
      return 'UTC' if offset == 0

      # keep track of the currently matched time zone
      current_zone = nil

      # loop through each timezone
      ActiveSupport::TimeZone.zones_map.each do |z|
        current_zone = z[0]

        # get time string in time zone
        timestring = Time.now.in_time_zone(current_zone).to_s

        # if time zone matches the offset, leave current_zone alone
        break if (current_zone != 'UTC' && timestring.slice(-5..-3).to_i == offset && timestring.slice(-2..-1).to_i == 0)
      end

      # if no time zone found, set to utc
      return current_zone.present? ? current_zone : 'UTC'
    end

    def help
      Helper.instance
    end

    class Helper
      include Singleton
      include ActionView::Helpers::TextHelper
    end
end

