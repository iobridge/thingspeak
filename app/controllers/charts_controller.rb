class ChartsController < ApplicationController
  before_filter :require_user, :only => [:edit]

  def edit
    # params[:id] is the windows ID
    @channel = current_user.channels.find(params[:channel_id])

    window_id = params[:id]
    logger.debug "Windows ID is #{window_id}"
    window = @channel.windows.find(window_id)
    options = window.options unless window.nil?
    logger.debug "Options for window #{window_id} are " + options.inspect

    render :partial => "charts/config", :locals => {
      :displayconfig => false,
      :title => @channel.name,
      :src => "/channels/#{@channel.id}/charts/#{window_id}",
      :options => options,
      :index => window_id,
      :width => Chart.default_width,
      :height => Chart.default_height
    }
  end

  def index
    set_channels_menu
    @channel = Channel.find(params[:channel_id])
    @channel_id = params[:channel_id]
    @domain = domain

    # default chart size
    @width = Chart.default_width
    @height = Chart.default_height

    check_permissions(@channel)
  end

  # show a chart with multiple series
  def multiple_series
    render :layout => false
  end

  def show
    # allow these parameters when creating feed querystring
    feed_params = ['key', 'api_key', 'apikey', 'days','start','end','round','timescale','average','median','sum','results','location','status','timezone']

    # set chart size
    width = params[:width].present? ? params[:width] : Chart.default_width
    @width_style = (width == 'auto') ? '' : "width: #{width.to_i - 25}px;"
    height = params[:height].present? ? params[:height] : Chart.default_height
    @height_style = (height == 'auto') ? '' : "height: #{height.to_i - 25}px;"

    # add extra parameters to querystring
    @qs = ''
    params.each do |p|
      @qs += "&#{p[0]}=#{p[1]}" if feed_params.include?(p[0])
    end

    # fix chart colors if necessary
    params[:color] = fix_color(params[:color])
    params[:bgcolor] = fix_color(params[:bgcolor])

    # set ssl
    ssl = (get_header_value('x_ssl') == 'true')
    @domain = domain(ssl)

    # should data be pushed off the end in dynamic chart
    @push = (params[:push] and params[:push] == 'false') ? false : true
    @results = params[:results]
    render :layout => false
  end

  # save chart options
  def update
    @channel = Channel.find(params[:channel_id])
    @status = 0

    # check permissions
    if current_user.present? && @channel.user_id == current_user.id
      logger.debug "Saving Data with new options " + params[:newOptions].to_s
      # save data
      if params[:newOptions]
        logger.debug "Updating new style options on window id #{params[:id]} with #{params[:newOptions][:options]}"
        window = @channel.windows.find(params[:id])
        window.options = params[:newOptions][:options]
        if !window.save
          raise "Couldn't save the Chart Window"
        end
      end
      if @channel.save
        @status = 1
      end

    end

    # return response: 1=success, 0=failure
    render :json => @status.to_json
  end

  private

  # fixes chart color if user forgets the leading '#'
  def fix_color(color)
    # check for 3 or 6 character hexadecimal value
    if (color and color.match(/^([0-9]|[a-f]|[A-F]){3}(([0-9]|[a-f]|[A-F]){3})?$/))
      color = '#' + color
    end

    return color
  end

end

