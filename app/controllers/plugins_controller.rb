class PluginsController < ApplicationController
  before_filter :require_user, :except => [:show_public, :show]
  before_filter :set_plugins_menu
  before_filter :check_permission, :only => ['edit', 'update', 'ajax_update', 'destroy']

  def check_permission
    @plugin = Plugin.find(params[:id])
    respond_with_error(:error_auth_required) and return if current_user.blank? || (@plugin.user_id != current_user.id)
  end

  def index
    @plugins = current_user.plugins

  end

  def public_plugins

    channel_id = params[:channel_id].to_i
    return if channel_id.nil?
    #private page should display all plugins
    #plugins = current_user.plugins.where("private_flag = true")
    @plugin_windows = []
    plugins = current_user.plugins
    plugins.each do |plugin|
      plugin.make_windows channel_id, api_domain #will only make the window the first time
      @plugin_windows = @plugin_windows + plugin.public_dashboard_windows(channel_id)

    end

    respond_to do |format|
      format.html { render :partial => 'plugins' }
    end

  end

  def private_plugins
    channel_id = params[:channel_id].to_i
    return if channel_id.nil?
    #private page should display all plugins
    @plugin_windows = []

    plugins = current_user.plugins

    plugins.each do |plugin|
      plugin.make_windows channel_id, api_domain #will only make the window the first time
      @plugin_windows = @plugin_windows + plugin.private_dashboard_windows(channel_id)
    end
    respond_to do |format|
      format.html { render :partial => 'plugins' }
    end
  end

  def create
    # add plugin with defaults
    @plugin = Plugin.new
    @plugin.html = read_file('app/views/plugins/default.html')
    @plugin.css = read_file('app/views/plugins/default.css')
    @plugin.js = read_file('app/views/plugins/default.js')
    @plugin.user_id = current_user.id
    @plugin.private_flag = true
    @plugin.save

    # now that the plugin is saved, we can create the default name
    @plugin.name = "#{t(:plugin_default_name)} #{@plugin.id}"
    @plugin.save

    # redirect to edit the newly created plugin
    redirect_to edit_plugin_path(@plugin.id)
  end

  def show
    @plugin = Plugin.find(params[:id])

    # make sure the user can access this plugin
    if (@plugin.private_flag == true)
      respond_with_error(:error_auth_required) and return if current_user.blank? || (@plugin.user_id != current_user.id)
    end

    @output = @plugin.html.sub('%%PLUGIN_CSS%%', @plugin.css).sub('%%PLUGIN_JAVASCRIPT%%', @plugin.js)

    if request.url.include? api_domain
      render :layout => false and return
    else
      protocol = ssl
      host = api_domain.split('://')[1]

      redirect_to :host => host,
      :protocol => protocol,
      :controller => "plugins",
      :action => "show",
      :id => @plugin.id and return
    end

  end

  def show_public

    @plugin = Plugin.find(params[:id])
    @output = @plugin.html.sub('%%PLUGIN_CSS%%', @plugin.css).sub('%%PLUGIN_JAVASCRIPT%%', @plugin.js)
    if @plugin.private?
      render :layout => false
    else
      if request.url.include? 'api_domain'
        render :layout => false
      else

      redirect_to :host => api_domain,
            :controller => "plugins",
            :action => "show",
            :id => @plugin.id
      end
    end
  end

  def edit
  end

  def update
    @plugin.update_attribute(:name, params[:plugin][:name])
    @plugin.update_attribute(:private_flag, params[:plugin][:private_flag])
    @plugin.update_attribute(:css, params[:plugin][:css])
    @plugin.update_attribute(:js, params[:plugin][:js])
    @plugin.update_attribute(:html,params[:plugin][:html])

    if @plugin.save

      @plugin.update_all_windows
      redirect_to plugins_path and return
    end

  end

  def ajax_update
    status = 0
    @plugin.update_attribute(:name, params[:plugin][:name])
    @plugin.update_attribute(:private_flag, params[:plugin][:private_flag])
    @plugin.update_attribute(:css, params[:plugin][:css])
    @plugin.update_attribute(:js, params[:plugin][:js])
    @plugin.update_attribute(:html, params[:plugin][:html])

    if @plugin.save
      @plugin.update_all_windows
      status = 1
    end

    # return response: 1=success, 0=failure
    render :json => status.to_json
  end

  def destroy
    @plugin.destroy
    redirect_to plugins_path
  end
end

