# == Schema Information
#
# Table name: channels
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  name          :string(255)
#  description   :string(255)
#  latitude      :decimal(15, 10)
#  longitude     :decimal(15, 10)
#  field1        :string(255)
#  field2        :string(255)
#  field3        :string(255)
#  field4        :string(255)
#  field5        :string(255)
#  field6        :string(255)
#  field7        :string(255)
#  field8        :string(255)
#  scale1        :integer
#  scale2        :integer
#  scale3        :integer
#  scale4        :integer
#  scale5        :integer
#  scale6        :integer
#  scale7        :integer
#  scale8        :integer
#  created_at    :datetime
#  updated_at    :datetime
#  elevation     :string(255)
#  last_entry_id :integer
#  public_flag   :boolean          default(FALSE)
#  options1      :string(255)
#  options2      :string(255)
#  options3      :string(255)
#  options4      :string(255)
#  options5      :string(255)
#  options6      :string(255)
#  options7      :string(255)
#  options8      :string(255)
#  social        :boolean          default(FALSE)
#  slug          :string(255)
#  status        :string(255)
#  url           :string(255)
#  video_id      :string(255)
#  video_type    :string(255)
#  clearing      :boolean          default(FALSE), not null
#  ranking       :integer
#

class Channel < ActiveRecord::Base
  include KeyUtilities

  belongs_to :user
  has_many :feeds
  has_many :daily_feeds
  has_many :api_keys, :dependent => :destroy
  has_many :taggings, :dependent => :destroy
  has_many :tags, :through => :taggings
  has_many :comments, :dependent => :destroy
  has_many :windows, :dependent => :destroy, :autosave => true
  accepts_nested_attributes_for :tags

  self.include_root_in_json = true

  attr_readonly :created_at

  after_commit :set_default_name
  after_commit :set_ranking, :unless => "ranking == calc_ranking"

  before_destroy :delete_feeds

  validates :video_type, :presence => true, :if => lambda{ |channel| !channel.video_id.nil? && !channel.video_id.empty?}

  scope :public_viewable, lambda { where("public_flag = true AND social != true") }
  scope :is_public, lambda { where("public_flag = true") }
  scope :active, lambda { where("channels.last_entry_id > 1 and channels.updated_at > ?", DateTime.now.utc - 7.day) }
  scope :being_cleared, lambda { where("clearing = true") }
  scope :by_array, lambda {|ids| { :conditions => ["id in (?)", ids.uniq] }  }
  scope :with_tag, lambda {|name| joins(:tags).where("tags.name = ?", name) }

  # pagination variables
  cattr_reader :per_page
  @@per_page = 15

  # how often the channel is updated
  def update_rate
    last_feeds = self.feeds.order('entry_id desc').limit(2)
    rate = (last_feeds.first.created_at - last_feeds.last.created_at) if last_feeds.length == 2
    return rate
  end

  # write key for a channel
  def write_api_key
    self.api_keys.where(:write_flag => true).first.api_key
  end

  # select options
  def select_options
    only = [:name, :created_at, :updated_at, :id, :last_entry_id]
    only += [:description] unless self.description.blank?
    only += [:latitude] unless self.latitude.blank?
    only += [:longitude] unless self.longitude.blank?
    only += [:elevation] unless self.elevation.blank?
    only += [:field1] unless self.field1.blank?
    only += [:field2] unless self.field2.blank?
    only += [:field3] unless self.field3.blank?
    only += [:field4] unless self.field4.blank?
    only += [:field5] unless self.field5.blank?
    only += [:field6] unless self.field6.blank?
    only += [:field7] unless self.field7.blank?
    only += [:field8] unless self.field8.blank?

    # return a hash
    return { :only => only }
  end

  # adds a feed to the channel
  def add_status_feed(status)
    # update the entry_id for the channel
    entry_id = self.next_entry_id
    self.last_entry_id = entry_id
    self.save
    # create the new feed with the correct status and entry_id
    self.feeds.create(:status => status, :entry_id => entry_id)
  end

  # get next last_entry_id for a channel
  def next_entry_id
    self.last_entry_id.nil? ? 1 : self.last_entry_id + 1
  end

  # for internal admin use, shows the ids of a channel per month (useful as a proxy for growth)
  def show_growth
    output = []
    date = self.feeds.order("entry_id asc").first.created_at

    # while the date is in the past
    while (date < Time.now)
      # get a feed on that day
      feed = self.feeds.where("created_at > ?", date).where("created_at < ?", date + 1.day).first
      # output the date and feed id
      output << "#{date.strftime('%Y-%m-%d')},#{feed.id}" if feed.present?
      # set the date 1 month further
      date = date + 1.month
    end

    # show the output
    puts output.join("\n")
  end

  # paginated hash for json and xml output
  # channels input must be paginated
  def self.paginated_hash(channels)
    {
      pagination:
      {
        current_page: channels.current_page,
        per_page: channels.per_page,
        total_entries: channels.total_entries,
      },
      channels: channels.as_json(Channel.public_options)
    }
  end

  # for to_json or to_xml, return only the public attributes
  def self.public_options
    {
      :root => false,
      :only => [:id, :name, :description, :latitude, :longitude, :last_entry_id, :elevation, :created_at, :ranking],
      :methods => :username,
      :include => { :tags => {:only => [:id, :name]}}
    }
  end

  # used when creating a channel
  def self.private_options
    {
      :root => false,
      :only => [:id, :name, :description, :latitude, :longitude, :last_entry_id, :elevation, :created_at, :ranking],
      :methods => :username,
      :include => {
        :tags => {:only => [:id, :name]},
        :api_keys => {:only => [:api_key, :write_flag]}
      }
    }
  end

  # login name of the user who created the channel
  def username; self.user.try(:login); end

  # custom as_json method to allow: root => false
  def as_json(options = nil)
    root = include_root_in_json
    root = options[:root] if options.try(:key?, :root)
    if root
      root = self.class.model_name.element if root == true
      { root => serializable_hash(options) }
    else
      serializable_hash(options)
    end
  end

  def private_windows *hidden
    if hidden.size >= 1
      return windows.where("private_flag = true and show_flag = #{hidden[0].to_s}")
    else
      return windows.where("private_flag = true" )
    end
  end

  # overloaded version witthout private/public flag for the has_many dependent destroy action
  def public_windows hidden
    return windows.where("private_flag = false and show_flag = #{hidden}")
  end
  # measure of activity in terms of feeds per time period

  def public?
    return public_flag
  end

  def video_changed?
    video_id_changed? || video_type_changed?
  end

  def location_changed?
    latitude_changed? || longitude_changed?
  end

  def feeds_changed?
    field1_changed? ||
      field2_changed? ||
      field3_changed? ||
      field4_changed? ||
      field5_changed? ||
      field6_changed? ||
      field7_changed? ||
      field8_changed?
  end

  def update_chart_portlets
    self.fields.each do |field|
      update_chart_portlet field, true
      update_chart_portlet field, false
    end
    #remove portlets for fields that don't exist
    #iterate all chart windows... and look for a matching field
    chartWindows = windows.where(:wtype => :chart )
    chartWindows.each do |window|
      if self.send(window.name).blank?
        window.destroy
      end

    end

  end

  def update_status_portlet isPrivate

    window = windows.where(:wtype => :status, :private_flag => isPrivate )

    status_html = "<iframe class=\"statusIFrame\" width=\"450\" height=\"260\" frameborder=\"0\"  src=\"/channels/#{id}/status/recent\"></iframe>"

    if window.nil? || window[0].nil?

        window = PortletWindow.new
        window.wtype = :status
        window.position = 1
        window.col = 1
        window.title = "window_status"
    else

      window = window[0]
    end

    window.private_flag = isPrivate
    window.html = status_html
    window.window_detail = PortletWindowDetail.new if window.window_detail.nil?
    self.windows.push window

  end

  def video_fields_valid?
    !video_id.nil? && !video_id.empty? && !video_type.nil? && !video_type.empty?
  end

  def update_video_portlet isPrivate
    window = windows.where(:wtype => :video, :private_flag => isPrivate )
    if video_fields_valid?
      youtube_html = "<iframe class=\"youtube-player\" type=\"text/html\" width=\"452\" height=\"260\" src=\"https://www.youtube.com/embed/#{video_id}?wmode=transparent\" frameborder=\"0\" wmode=\"Opaque\" ></iframe>"
      vimeo_html = "<iframe class=\"vimeo-player\" type=\"text/html\" width=\"452\" height=\"260\" src=\"http://player.vimeo.com/video/#{video_id}\" frameborder=\"0\"></iframe>"
      if window.nil? || window[0].nil?
        window = PortletWindow.new
        window.wtype = :video
        window.position = 1
        window.col = 1
        window.title = "window_channel_video"
      else
        window = window[0]
      end
      window.private_flag = isPrivate
      window.html = youtube_html if video_type == 'youtube'
      window.html = vimeo_html if video_type == 'vimeo'
      window.window_detail = PortletWindowDetail.new if window.window_detail.nil?
      self.windows.push window
    else
      unless window[0].nil?
        window[0].delete
      end
    end
  end

  def update_location_portlet isPrivate
    window = windows.where(:wtype => :location, :private_flag => isPrivate )
    if !latitude.nil? && !longitude.nil?
      maps_html = "<iframe width=\"450\" height=\"260\" frameborder=\"0\" scrolling=\"no\" " +
        "src=\"/channels/#{id}/maps/channel_show?width=450&height=260\"></iframe>"
      if window.nil? || window[0].nil?
        window = PortletWindow.new
        window.wtype = :location
        window.position = 0
        window.col = 1
        window.title = "window_map"
      else
        window = window[0]
      end
    window.private_flag = isPrivate
      window.html = maps_html
      window.window_detail = PortletWindowDetail.new if window.window_detail.nil?

      self.windows.push window

    else
      unless window[0].nil?

        window[0].delete
      end
    end
  end

  # get recent status messages from channel
  def recent_statuses
    self.feeds.select('status, created_at, entry_id').order('created_at DESC').limit(30).collect {|f| f unless f.status.blank? }.compact
  end

  def latest_feed
    self.feeds.where(:entry_id => self.last_entry_id).first
  end

  def delete_feeds
    if self.feeds.count < 1000
      Feed.delete_all(["channel_id = ?", self.id])
      DailyFeed.delete_all(["channel_id = ?", self.id])
      begin
        self.update_attribute(:last_entry_id, nil)
      rescue Exception => e
      end

    else
      self.update_attribute(:clearing, true)
      Resque.enqueue(ClearChannelJob, self.id)
    end
  end

  # true if channel is active
  def active?
    return (last_entry_id and updated_at and last_entry_id > 1 and updated_at > DateTime.now.utc - 1.days)
  end

  def list_tags
    (self.tags.collect { |t| t.name }).join(', ')
  end

  def save_tags(tags)
    # for each tag
    tags.split(',').each do |name|
      tag = Tag.find_by_name(name.strip)
      # save if new tag
      if tag.nil?
        tag = Tag.new
        tag.name = name.strip
        tag.save
      end

      tagging = Tagging.find(:first, :conditions => { :tag_id => tag.id, :channel_id => self.id})
      # save if new tagging
      if tagging.nil?
        tagging = Tagging.new
        tagging.channel_id = self.id
        tagging.tag_id = tag.id
        tagging.save
      end
    end

    # delete any tags that were removed
    self.remove_tags(tags)
  end

  # if tags don't exist anymore, remove them
  def remove_tags(tags)
    tag_array = tags.split(',')
    # remove white space
    tag_array = tag_array.collect {|t| t.strip }

    # get all taggings for this channel
    taggings = Tagging.find(:all, :conditions => { :channel_id => self.id }, :include => :tag)

    # check for existence
    taggings.each do |tagging|
      # if tagging is not in list
      if !tag_array.include?(tagging.tag.name)
        # delete tagging
        tagging.delete
      end
    end
  end

  def add_write_api_key
    write_key = self.api_keys.new
    write_key.user = self.user
    write_key.write_flag = true
    write_key.api_key = generate_api_key
    write_key.save
  end

  def queue_react
    self.reacts.on_insertion.each do |react|
      begin
        Resque.enqueue(ReactJob, react.id)
      rescue Exception => e

      end
    end
  end

  def field_label(field_number)
    self.attributes["field#{field_number}"]
  end

  def fields
    fields = attribute_names.reject { |x|
      !(x.index('field') && self[x] && !self[x].empty?)
    }
  end

  def calc_ranking
    result = 0
    result = result + 15 unless name.blank?
    result = result + 20 unless description.blank?
    result = result + 15 unless latitude.blank? || longitude.blank?
    result = result + 15 unless url.blank?
    result = result + 15 unless video_id.blank? || video_type.blank?

    result = result + 20 unless tags.empty?
    result
  end

  def set_windows
    #check for video window
    if video_changed?
      update_video_portlet true
      update_video_portlet false
    end

    #does channel have a location and corresponding google map
    if location_changed?
      update_location_portlet true
      update_location_portlet false
    end

    #does channel have status and corresponding status window. Add the status window no matter what. Only display if it has values
    update_status_portlet true
    update_status_portlet false

    #does channel have a window for every chart element
    if feeds_changed?
      update_chart_portlets
    end
  end

  private

    def set_ranking
      update_attribute(:ranking, calc_ranking) unless ranking == calc_ranking

    end
    def update_chart_portlet (field, isPrivate)

      chartWindows = windows.where(:type => "ChartWindow", :name => "field#{field.last.to_s}", :private_flag => isPrivate )
      if chartWindows.nil? || chartWindows[0].nil?
        window = ChartWindow.new
        window.wtype = :chart
        window.position = 0
        window.col = 0
        window.title = "window_field_chart"
        window.name = field.to_s
        window.window_detail = ChartWindowDetail.new
        window.window_detail.options = "&results=60&dynamic=true"
      else
        window = chartWindows[0]
        # If there are options, use them.. if options are not available, then assign defaults
        window.window_detail.options ||= "&results=60&dynamic=true"
      end

      window.window_detail.field_number = field.last
      window.private_flag = isPrivate
      windows.push window
      window.html ="<iframe id=\"iframe#{window.id}\" width=\"450\" height=\"260\" style=\"border: 1px solid #cccccc;\" src=\"/channels/#{id}/charts/#{field.last.to_s}?width=450&height=260::OPTIONS::\" ></iframe>"

      if !window.save
        raise "The Window could not be saved"
      end
    end

    def set_default_name
      update_attribute(:name, "#{I18n.t(:channel_default_name)} #{self.id}") if self.name.blank?
    end





end

