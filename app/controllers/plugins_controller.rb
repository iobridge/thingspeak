class PluginsController < ApplicationController
  before_filter :authenticate_via_api_key!, :only => [:index]
  before_filter :require_user, :except => [:show_public, :show, :public]
  before_filter :set_plugins_menu
  before_filter :check_permission, :only => ['edit', 'update', 'ajax_update', 'destroy']

  def check_permission
    @plugin = Plugin.find(params[:id])
    respond_with_error(:error_auth_required) and return if current_user.blank? || (@plugin.user_id != current_user.id)
  end

  def new; ; end
  def edit; ; end

  # get list of public plugins
  def public
    # error if page 0
    respond_with_error(:error_resource_not_found) and return if params[:page] == '0'

    # default blank response
    @plugins = Plugin.where(:id => 0).paginate :page => params[:page]

    # get plugins
    @plugins = Plugin.where("public_flag = true").order('updated_at DESC').paginate :page => params[:page]

    respond_to do |format|
      format.html
      format.json { render :json => Plugin.paginated_hash(@plugins).to_json }
      format.xml { render :xml => Plugin.paginated_hash(@plugins).to_xml(:root => 'response') }
    end
  end

  def index
    @plugins = current_user.plugins
    respond_to do |format|
      format.html
      format.json { render :json => @plugins.to_json(Plugin.public_options) }
      format.xml { render :xml => @plugins.to_xml(Plugin.public_options) }
    end
  end

  def public_plugins
    channel_id = params[:channel_id].to_i
    return if channel_id.nil?
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

    # set default template
    template = 'default'

    # use case statement to set template, since user input is untrusted
    case params[:template]
    when 'gauge' then template = 'gauge'
    when 'chart' then template = 'chart'
    end

    # set template dynamically
    @plugin.html = read_file("app/views/plugins/templates/#{template}.html")
    @plugin.css = read_file("app/views/plugins/templates/#{template}.css")
    @plugin.js = read_file("app/views/plugins/templates/#{template}.js")

    @plugin.user_id = current_user.id
    @plugin.public_flag = false
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
    if (@plugin.private?)
      respond_with_error(:error_auth_required) and return if current_user.blank? || (@plugin.user_id != current_user.id)
    end

    @output = @plugin.html.sub('%%PLUGIN_CSS%%', @plugin.css).sub('%%PLUGIN_JAVASCRIPT%%', @plugin.js)

    render :layout => false
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

  def update
    @plugin.update_attribute(:name, params[:plugin][:name])
    @plugin.update_attribute(:public_flag, params[:plugin][:public_flag])
    @plugin.update_attribute(:css, params[:plugin][:css])
    @plugin.update_attribute(:js, params[:plugin][:js])
    @plugin.update_attribute(:html,params[:plugin][:html])

    if @plugin.save
      @plugin.update_all_windows
      flash[:notice] = I18n.t(:plugin_save_message)
      redirect_to edit_plugin_path(@plugin) and return
    end
  end

  def ajax_update
    status = 0
    @plugin.update_attribute(:name, params[:plugin][:name])
    @plugin.update_attribute(:public_flag, params[:plugin][:public_flag])
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

