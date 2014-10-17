# == Schema Information
#
# Table name: plugins
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  user_id     :integer
#  html        :text
#  css         :text
#  js          :text
#  created_at  :datetime
#  updated_at  :datetime
#  public_flag :boolean          default(FALSE)
#

class Plugin < ActiveRecord::Base
  belongs_to :user
  has_many :windows, -> { where window_type: 'plugin' }, :foreign_key => :content_id, :source => :window
  before_destroy { |record| record.windows.each { |window| window.delete } }

  # pagination variables
  cattr_reader :per_page
  @@per_page = 15

  # paginated hash for json and xml output
  # plugins input must be paginated
  def self.paginated_hash(plugins)
    {
      pagination:
      {
        current_page: plugins.current_page,
        per_page: plugins.per_page,
        total_entries: plugins.total_entries,
      },
      plugins: plugins.as_json(Plugin.public_options)
    }
  end

  # for to_json or to_xml, return only the public attributes
  def self.public_options
    {
      :root => false,
      :only => [:id, :name, :created_at, :public_flag],
      :methods => [:username, :url]
    }
  end

  # login name of the user who created the plugin
  def username; self.user.try(:login); end

  # url for the plugin
  def url
    domain = 'https://thingspeak.com'
    domain = 'http://staging.thingspeak.com' if Rails.env.staging?
    domain = 'http://127.0.0.1:3000' if Rails.env.development?
    return "#{domain}/plugins/#{self.id}"
  end

  def destroy_window
    window_id = Window.where(content_id: self.id, window_type: 'plugin').first.id
    Window.delete(window_id)
  end

  def public?; public_flag == true; end
  def private?; public_flag == false; end

  def has_private_windows(channel_id)
    has_private_windows = false
    windows.each do |window|

      if window.private? && window.channel_id == channel_id
        has_private_windows = true

      end

    end

    return has_private_windows
  end

  def has_public_windows(channel_id)
    has_public_windows = false
    windows.each do |window|
      has_public_windows = true if !window.private? && window.channel_id == channel_id
    end
    return has_public_windows
  end

  #private_dashboard_visibility
  def private_dashboard_windows(channel_id)
    dashboard_windows channel_id, true
  end

  def public_dashboard_windows(channel_id)
    dashboard_windows channel_id, false
  end
  def dashboard_windows(channel_id, privacy)
    dashboard_windows = []
    windows.each do |window|
      if window.private_flag == privacy && !window.show_flag && channel_id == window.channel_id
        dashboard_windows << window
      end
    end
    dashboard_windows
  end

  #public_dashboard_visibility
  def public_window
    public_window = nil
    windows.each do |window|
      if !window.private_flag # && !window.show_flag
        public_window = window
      end
    end
    unless public_window.nil?
      public_window
    else
      nil
    end
  end

  def make_windows(channel_id, api_domain)
    #create all the windows as appropriate
    #Private plugins have one window..
    #Public plugins have a private/private windows, private/public window and a public window
    if !has_public_windows(channel_id) && self.public?
      windows << Window.new_from(self, channel_id, :public, api_domain)
    else
      update_windows(channel_id)
    end

    if !has_private_windows(channel_id)
      windows << Window.new_from(self, channel_id, :private, api_domain)
    end
    save
  end

  def update_windows(channel_id)

    windows.each do |window|
      window.name = self.name
      window.save
    end

    if has_public_windows(channel_id) && self.private?
      windows.delete(public_window.destroy) unless public_window.nil?
    end

  end

  def update_all_windows
    channel_ids = Set.new
    windows.each do |window|
      window.name = self.name
      channel_ids.add( window.channel_id)
      window.save
    end
    channel_ids.each do |id|
      if has_public_windows(id) && self.private?
        windows.delete(public_window.destroy) unless public_window.nil?
      end
    end
  end

end

