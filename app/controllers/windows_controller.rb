class WindowsController < ApplicationController
  before_filter :require_user, :except => [:index, :html, :iframe]

  def hide
    window = Window.find(params[:id])
    window.show_flag = false
    if window.save
      render :text => window.id.to_s
    else
      render :text => '-1'
    end
  end

  # Call WindowsController.display when we want to display a window on the dashboard
  #  params[:visibility_flag] is whether it is the private or public dashboard
  #  params[:plugin] is for displaying a plugin, instead of a window
  #  params[:id] is the window ID for conventional windows, but the plugin_id for plugins
  #  params[:channel_id] is the channel_id
  def display
    @visibility = params[:visibility_flag]

    window = Window.find(params[:id])
    window = Window.new if window.nil?
    window.show_flag = true
    #Just save this change, then modify the object before rendering the JSON
    savedWindow = window.save

    config_window window

    @mychannel = current_user && current_user.id == window.channel.user_id

    if savedWindow
      render :json => window.to_json
    else
      render :json => 'An error occurred'.to_json
    end
  end

  def config_window(window)
    if window.type == "PluginWindow"
      pluginName = Plugin.find(window.window_detail.plugin_id).name
      window.title = t(window.title, {:name => pluginName})
    elsif window.type == "ChartWindow"
      window.title = t(window.title, {:field_number => window.window_detail.field_number})
      options = window.becomes(ChartWindow).window_detail.options if !window.becomes(ChartWindow).window_detail.nil?
      options ||= ""
      window.html["::OPTIONS::"] = options unless window.html.nil? || window.html.index("::OPTIONS::").nil?
    else
      window.title = t(window.title)
    end
  end
  def html
    window = Window.find(params[:id])
    options = window.window_detail.options unless window.window_detail.nil? || window.type!="ChartWindow"
    window.html["::OPTIONS::"] = options unless window.html.nil? || window.html.index("::OPTIONS::").nil?
    html = window.html

    render :text => html
  end

  def iframe
    window = Window.find(params[:id])
    options = window.window_detail.options unless window.window_detail.nil? || window.type!="ChartWindow"
    window.html["::OPTIONS::"] = options unless window.html.nil? || window.html.index("::OPTIONS::").nil?
    iframe_html = window.html

    iframe_html = iframe_html.gsub(/src=\"[\/.]/, 'src="' + api_domain);
    render :text => iframe_html
  end

  def index
    channel = Channel.find(params[:channel_id])

    channel.update_status_portlet false if (channel.windows.select { |w| w.wtype == :status && w.private_flag == false } )
    channel.update_status_portlet true if (channel.windows.select { |w| w.wtype == :status && w.private_flag == true } )
    channel.update_video_portlet false if (channel.windows.select { |w| w.wtype == :video && w.private_flag == false } )
    channel.update_video_portlet true if (channel.windows.select { |w| w.wtype == :video && w.private_flag == true } )
    channel.update_location_portlet false  if (channel.windows.select { |w| w.wtype == :location && w.private_flag == false } )
    channel.update_location_portlet true  if (channel.windows.select { |w| w.wtype == :location && w.private_flag == true } )
    channel.update_chart_portlets if (channel.windows.select { |w| w.wtype == :chart } )
    windows = channel.public_windows(true).order(:position) unless params[:channel_id].nil?

    if channel.recent_statuses.nil? || channel.recent_statuses.size <= 0
      @windows = windows.delete_if { |w| w.wtype == "status"  }
    else
      @windows = windows
    end

    @windows.each do |window|

      if window.type == "PluginWindow"
        pluginName = Plugin.find(window.window_detail.plugin_id).name
        window.title = t(window.title, {:name => pluginName})
      elsif window.type == "ChartWindow"
        window.title = t(window.title, {:field_number => window.window_detail.field_number})
        options = window.becomes(ChartWindow).window_detail.options if !window.becomes(ChartWindow).window_detail.nil?
        options ||= ""
        window.html["::OPTIONS::"] = options unless window.html.nil? || window.html.index("::OPTIONS::").nil?
      else
        window.title = t(window.title)
      end

    end

    respond_to do |format|
      format.html
      format.json { render :json => @windows.as_json( :include => [:window_detail] )   }
    end
  end

  # This is going to display windows that are hidden (show_flag = false)
  #  The "visibility_flag" param indicates whether it's public or private visibility
  def hidden_windows
    @visibility = params[:visibility_flag]
    channel = Channel.find(params[:channel_id])

    if @visibility == "private"
      @windows = channel.private_windows(false) unless channel.nil?
    else
      @windows = channel.public_windows(false) unless channel.nil?
    end
    @windows.reject! { |window| window.type == "PluginWindow" }
    @windows.each do |window|
      if window.type == "PluginWindow"
      elsif window.type == "ChartWindow"
        window.title = t(window.title, {:field_number => window.window_detail.field_number})
        options = window.becomes(ChartWindow).window_detail.options unless window.becomes(ChartWindow).window_detail.nil?
        options ||= ""
        window.html["::OPTIONS::"] = options unless window.html.nil? || window.html.index("::OPTIONS::").nil?
      else
        window.title = t(window.title)
      end
    end

    respond_to do |format|
      format.html { render :partial => "hidden_windows" }
      #      format.json { render :json => @windows.as_json( :include => [:window_detail] )   }
    end
  end

  def private_windows
    channel = Channel.find(params[:channel_id])

    channel.update_status_portlet false if (channel.windows.select { |w| w.wtype == :status && w.private_flag == false } )
    channel.update_status_portlet true if (channel.windows.select { |w| w.wtype == :status && w.private_flag == true } )
    channel.update_video_portlet false if (channel.windows.select { |w| w.wtype == :video && w.private_flag == false } )
    channel.update_video_portlet true if (channel.windows.select { |w| w.wtype == :video && w.private_flag == true } )
    channel.update_location_portlet false  if (channel.windows.select { |w| w.wtype == :location && w.private_flag == false } )
    channel.update_location_portlet true  if (channel.windows.select { |w| w.wtype == :location && w.private_flag == true } )
    channel.update_chart_portlets if (channel.windows.select { |w| w.wtype == :chart } )

    windows = channel.private_windows(true).order(:position) unless params[:channel_id].nil?

    if channel.recent_statuses.nil? || channel.recent_statuses.size <= 0
      @windows = windows.delete_if { |w| w.wtype == "status" }
    else
      @windows = windows
    end

    @windows.each do |window|
      if window.type == "PluginWindow"
        windowDetail = window.window_detail
        pluginName = Plugin.find(windowDetail.plugin_id).name
        window.title = t(window.title, {:name => pluginName})
      elsif window.type == "ChartWindow"
        window.title = t(window.title, {:field_number => window.window_detail.field_number})
        options = window.becomes(ChartWindow).window_detail.options unless window.becomes(ChartWindow).window_detail.nil?
        options ||= ""
        window.html["::OPTIONS::"] = options unless window.html.nil? || window.html.index("::OPTIONS::").nil?
      else
        window.title = t(window.title)
      end
    end

    respond_to do |format|
      format.html
      format.json { render :json => @windows.as_json( :include => [:window_detail] )   }
    end
  end


  def update
    logger.info "We're trying to update the windows with " + params.to_s
    #params for this put are going to look like
    #  page"=>"{\"col\":0,\"positions\":[1,2,3]}"
    #So.. the position values are Windows.id  They should get updated with the ordinal value based
    # on their array position and the column should get updated according to col value.
    # Since the windows are order by position, when a window record changes from
    # col1,position0 -> col0,position0 the entire new column is reordered.
    # The old column is missing a position, but the remaining are just left to their order
    # (ie., 0,1,2 become 1,2)  Unless they are also changed

    # First parse the JSON in params["page"] ...
    values = JSON(params[:page])

    # .. then find each window and update with new ordinal position and col.
    logger.info "Channel id = " + params[:channel_id].to_s
    @channel = current_user.channels.find(params[:channel_id])
    col = values["col"]
    saved = true
    values["positions"].each_with_index do |p,i|
      windows = @channel.windows.where({:id => p}) unless p.nil?
      unless windows.nil? || windows.empty?
        w = windows[0]
        w.position = i
        w.col = col
        if !w.save
          saved = false
        end
      end
    end
    if saved
      render :text => '0'
    else
      render :text => '-1'
    end

  end
end

