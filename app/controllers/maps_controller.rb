class MapsController < ApplicationController

  # show map with channel's location
  def channel_show
    set_map_vars
    render :layout => false
  end

  # show social map with feed points as markers
  def show
    set_map_vars
    render :layout => false
  end

  # set map variables
  def set_map_vars
    # allow these parameters when creating feed querystring
    feed_params = ['key','days','start','end','round','timescale','average','median','sum','results','status']

    # default map size
    @width = default_width
    @height = default_height

    # add extra parameters to querystring
    @qs = ''
    params.each do |p|
      @qs += "&#{p[0]}=#{p[1]}" if feed_params.include?(p[0])
    end

    # set ssl
    @ssl = (get_header_value('x_ssl') == 'true')
    @map_domain = @ssl ? 'https://maps-api-ssl.google.com' : 'http://maps.google.com'
    @domain = domain(@ssl)
  end

  private
    def default_width
      450
    end

    def default_height
      250
    end
end
