class WindowsController < ApplicationController
  before_filter :require_user, :except => [:index, :html, :iframe]

  # hides a window, returns the window id if successful or '-1' if failure
  def hide
    window = Window.find(params[:id])
    window.show_flag = false
    if window.save
      render :text => window.id.to_s
    else
      render :text => '-1'
    end
  end

  # displays a window on the dashboard
  def display
    window = Window.find(params[:id])
    window.show_flag = true
    # save this change
    saved_window = window.save

    # modify the object before rendering the JSON
    window.set_title_for_display!
    window.set_html_for_display!

    # if the window was saved successfully
    if saved_window
      render :json => window.to_json
    else
      render :json => 'An error occurred'.to_json
    end
  end

  def html
    window = Window.find(params[:id])
    window.set_html_for_display!
    render :text => window.html
  end

  def iframe
    window = Window.find(params[:id])
    window.set_html_for_display!
    iframe_html = window.html
    # set the domain correctly
    iframe_html = iframe_html.gsub(/src=\"[\/.]/, 'src="' + api_domain);
    render :text => iframe_html
  end

  def index
    channel = Channel.find(params[:channel_id])
    windows = channel.public_windows(true).order(:position) unless params[:channel_id].nil?

    if channel.recent_statuses.blank?
      @windows = windows.delete_if { |w| w.window_type == "status"  }
    else
      @windows = windows
    end

    @windows.each do |window|
      # modify the object before rendering the JSON
      window.set_title_for_display!
      window.set_html_for_display!
    end

    respond_to do |format|
      format.html
      format.json { render :json => @windows.as_json   }
    end
  end

  # This is going to display windows that are hidden (show_flag = false)
  #  The "visibility_flag" param indicates whether it's public or private visibility
  def hidden_windows
    @visibility = params[:visibility_flag]
    channel = Channel.find(params[:channel_id])

    if @visibility == "private"
      @windows = channel.private_windows(false)
    else
      @windows = channel.public_windows(false)
    end
    @windows.reject! { |window| window.window_type == "plugin" }
    @windows.each do |window|
      # modify the object before rendering the JSON
      window.set_title_for_display!
      window.set_html_for_display!
    end

    respond_to do |format|
      format.html { render :partial => "hidden_windows" }
      format.json { render :json => @windows.as_json   }
    end
  end

  def private_windows
    channel = Channel.find(params[:channel_id])
    windows = channel.private_windows(true).order(:position)

    if channel.recent_statuses.blank?
      @windows = windows.delete_if { |w| w.window_type == "status" }
    else
      @windows = windows
    end

    @windows.each do |window|
      # modify the object before rendering the JSON
      window.set_title_for_display!
      window.set_html_for_display!
    end

    respond_to do |format|
      format.html
      format.json { render :json => @windows.as_json }
    end
  end


  def update
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
    @channel = current_user.channels.find(params[:channel_id])
    col = values["col"]
    saved = true
    values["positions"].each_with_index do |p, index|
      window = @channel.windows.where({:id => p}).first unless p.nil?
      if window.present?
        window.position = index
        window.col = col
        if !window.save
          saved = false
        end
      end
    end
    # if the windows were saved successfully
    if saved
      render :text => '0'
    else
      render :text => '-1'
    end

  end
end

