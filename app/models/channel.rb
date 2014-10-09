# == Schema Information
#
# Table name: channels
#
#  id                        :integer          not null, primary key
#  user_id                   :integer
#  name                      :string(255)
#  description               :string(255)
#  latitude                  :decimal(15, 10)
#  longitude                 :decimal(15, 10)
#  field1                    :string(255)
#  field2                    :string(255)
#  field3                    :string(255)
#  field4                    :string(255)
#  field5                    :string(255)
#  field6                    :string(255)
#  field7                    :string(255)
#  field8                    :string(255)
#  scale1                    :integer
#  scale2                    :integer
#  scale3                    :integer
#  scale4                    :integer
#  scale5                    :integer
#  scale6                    :integer
#  scale7                    :integer
#  scale8                    :integer
#  created_at                :datetime
#  updated_at                :datetime
#  elevation                 :string(255)
#  last_entry_id             :integer
#  public_flag               :boolean          default(FALSE)
#  options1                  :string(255)
#  options2                  :string(255)
#  options3                  :string(255)
#  options4                  :string(255)
#  options5                  :string(255)
#  options6                  :string(255)
#  options7                  :string(255)
#  options8                  :string(255)
#  social                    :boolean          default(FALSE)
#  slug                      :string(255)
#  status                    :string(255)
#  url                       :string(255)
#  video_id                  :string(255)
#  video_type                :string(255)
#  clearing                  :boolean          default(FALSE), not null
#  ranking                   :integer
#  user_agent                :string(255)
#  realtime_io_serial_number :string(36)
#  metadata                  :text
#

class Channel < ActiveRecord::Base
  include KeyUtilities
  # geolocation search: Channel.within(miles, :origin => [latitude, longitude]).to_a
  # example: channels = Channel.within(4000, :origin => [4, 6]).to_a
  # channels.sort_by{|s| s.distance_to([4, 6])}
  acts_as_mappable :default_units => :kms, :default_formula => :sphere,
    :distance_field_name => :distance, :lat_column_name => :latitude, :lng_column_name => :longitude

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

  before_destroy :delete_feeds

  validates :video_type, :presence => true, :if => lambda{ |channel| channel.video_id.present? }

  scope :public_viewable, lambda { where("public_flag = true AND social != true") }
  scope :not_social, lambda { where("social != true") }
  scope :is_public, lambda { where("public_flag = true") }
  scope :active, lambda { where("channels.last_entry_id > 1 and channels.updated_at > ?", DateTime.now.utc - 7.day) }
  scope :being_cleared, lambda { where("clearing = true") }
  scope :by_array, lambda {|ids| { :conditions => ["id in (?)", ids.uniq] }  }
  scope :with_tag, lambda {|name| joins(:tags).where("tags.name = ?", name) }

  # pagination variables
  cattr_reader :per_page
  @@per_page = 15

  # replace channel values: %%channel_1417_field_1%% is replaced with appropriate value
  def self.replace_values(input, user)
    return input.gsub(/%%channel_\d+_field_\d+%%/) { |string| Channel.value_from_string(string, user) }
  end

  # access a last value by string: channel_1417_field_1
  def self.value_from_string(channel_string, user)
    # remove % from the string and create the array
    channel_array = channel_string.gsub('%', '').split('_')
    # exit if the string doesn't have 4 parts
    return nil if channel_array.length != 4

    # get the channel
    channel = Channel.find(channel_array[1])
    # exit if the channel is not public or not owned by the user
    return nil if !(channel.public_flag? || channel.user_id == user.try(:id))
    # get the field id
    field_id = channel_array[3].to_i

    # get the feed
    begin
      # add a timeout since this query may be really long if there is a lot of data,
      # but the last instance of the field is very far back
      Timeout.timeout(5, Timeout::Error) do
        # look for a feed where the value isn't null
        @feed = Feed.where(:channel_id => channel.id)
          .where("field? is not null", field_id)
          .select("entry_id, field#{field_id}")
          .order('entry_id desc')
          .first
      end
    rescue Timeout::Error
    rescue
    end

    # no feed found
    return nil if @feed.blank?

    # return the feed value
    return @feed["field#{field_id}"]
  end


  # search for public channels within a certain distance from the origin
  # requires latitude, longitude, and distance to be present as options keys
  # distance is in kilometers
  def self.location_search(options = {})
    # set the origin
    origin = [options[:latitude].to_f, options[:longitude].to_f]
    # query the database
    channels = Channel.public_viewable.within(options[:distance].to_f, :origin => origin)
    # sort channels by distance
    return channels.sort_by{|c| c.distance_to(origin)}
  end

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
  def select_options(options = nil)
    only = [:name, :created_at, :updated_at, :id, :last_entry_id]
    only += [:description] if self.description.present?
    only += [:metadata] if options.present? && options[:metadata] == 'true'
    only += [:latitude] if self.latitude.present?
    only += [:longitude] if self.longitude.present?
    only += [:elevation] if self.elevation.present?
    only += [:field1] if self.field1.present?
    only += [:field2] if self.field2.present?
    only += [:field3] if self.field3.present?
    only += [:field4] if self.field4.present?
    only += [:field5] if self.field5.present?
    only += [:field6] if self.field6.present?
    only += [:field7] if self.field7.present?
    only += [:field8] if self.field8.present?

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
      :only => [:id, :name, :description, :metadata, :latitude, :longitude, :last_entry_id, :elevation, :created_at, :ranking],
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

  # private windows
  def private_windows(show_flag = false)
    show_flag = (show_flag.to_s == 'true') ? true : false
    return self.windows.where("private_flag = true AND show_flag = ?", show_flag)
  end

  # public windows
  def public_windows(show_flag = false)
    show_flag = (show_flag.to_s == 'true') ? true : false
    return self.windows.where("private_flag = false AND show_flag = ?", show_flag)
  end

  # check if the channel is public
  def public?; self.public_flag; end

  # check if the video has changed
  def video_changed?; video_id_changed? || video_type_changed?; end

  # check if the location has changed
  def location_changed?; latitude_changed? || longitude_changed?; end

  # check if the any of the fields have changed
  def fields_changed?
    field1_changed? || field2_changed? || field3_changed? || field4_changed? ||
      field5_changed? || field6_changed? || field7_changed? || field8_changed?
  end

  # update the chart windows
  def update_chart_windows
    # for each field
    self.fields.each do |field_name|
      # if the field exists, update the private and public chart window
      if self.send("#{field_name}").present?
        update_chart_window(field_name, true)
        update_chart_window(field_name, false)
      end
    end

    # remove chart windows for fields that don't exist
    chart_windows = windows.where(window_type: 'chart')
    chart_windows.each do |chart_window|
      chart_window.destroy if self.send("field#{chart_window.content_id}").blank?
    end
  end

  # update the status window
  def update_status_window(private_flag)
    window = windows.where(:window_type => 'status', :private_flag => private_flag).first
    status_html = "<iframe class=\"statusIFrame\" width=\"450\" height=\"260\" frameborder=\"0\"  src=\"/channels/#{self.id}/status/recent\"></iframe>"

    # if no status window, create one
    if window.blank?
      window = Window.new(window_type: 'status', position: 1, col: 1, title: 'window_status', private_flag: private_flag)
    end

    # set html and add the window
    window.html = status_html
    self.windows.push(window)
  end

  # update the video window
  def update_video_window(private_flag)
    window = windows.where(:window_type => 'video', :private_flag => private_flag).first

    # if the video fields are both present
    if video_id.present? && video_type.present?
      youtube_html = "<iframe class=\"youtube-player\" type=\"text/html\" width=\"452\" height=\"260\" src=\"https://www.youtube.com/embed/#{video_id}?wmode=transparent\" frameborder=\"0\" wmode=\"Opaque\" ></iframe>"
      vimeo_html = "<iframe class=\"vimeo-player\" type=\"text/html\" width=\"452\" height=\"260\" src=\"http://player.vimeo.com/video/#{video_id}\" frameborder=\"0\"></iframe>"

      # if no video window, create one
      if window.blank?
        window = Window.new(window_type: 'video', position: 1, col: 1, title: 'window_channel_video', private_flag: private_flag)
      end

      # add the html and save the window
      window.html = youtube_html if video_type == 'youtube'
      window.html = vimeo_html if video_type == 'vimeo'
      self.windows.push(window)
    # else delete the window
    else
      window.delete if window.present?
    end
  end

  # update the location window
  def update_location_window(private_flag)
    window = windows.where(:window_type => 'location', :private_flag => private_flag).first

    # if the latitude and longitude are present
    if latitude.present? && longitude.present?
      maps_html = "<iframe width=\"450\" height=\"260\" frameborder=\"0\" scrolling=\"no\" " +
        "src=\"/channels/#{id}/maps/channel_show?width=450&height=260\"></iframe>"

      # if no location window, create one
      if window.blank?
        window = Window.new(window_type: 'location', position: 0, col: 1, title: 'window_map', private_flag: private_flag)
      end

      # add the html and save the window
      window.html = maps_html
      self.windows.push(window)
    # else delete the window
    else
      window.delete if window.present?
    end
  end

  # get recent status messages from channel
  def recent_statuses
    self.feeds.select('status, created_at, entry_id').order('created_at DESC').limit(30).collect {|f| f unless f.status.blank? }.compact
  end

  # get the latest feed using the channel's last_entry_id
  def latest_feed
    self.feeds.where(:entry_id => self.last_entry_id).first
  end

  def delete_feeds
    # if a small number of feeds or redis is not present
    if self.feeds.count < 1000 || REDIS_ENABLED == false
      Feed.delete_all(["channel_id = ?", self.id])
      DailyFeed.delete_all(["channel_id = ?", self.id])
      begin
        self.update_attribute(:last_entry_id, nil)
      rescue Exception => e
      end
    # else delete via background resque job
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

      tagging = Tagging.where(tag_id: tag.id, channel_id: self.id).first
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
    taggings = Tagging.where(channel_id: self.id).includes(:tag)

    # check for existence
    taggings.each do |tagging|
      # if tagging is not in list
      if !tag_array.include?(tagging.tag.name)
        # delete tagging
        tagging.delete
      end
    end
  end

  # add a write api key to the channel
  def add_write_api_key
    write_key = self.api_keys.new
    write_key.user = self.user
    write_key.write_flag = true
    write_key.api_key = generate_api_key
    write_key.save
  end

  # runs after a feed is posted
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

  # get the valid fields as an array, for example: ["field1", "field2", "field3", "field5"]
  def fields
    fields = attribute_names.reject { |x|
      !(x.index('field') && self[x] && !self[x].empty?)
    }
  end

  # set the ranking correctly for the channel
  def set_ranking
    new_ranking = 0
    new_ranking += 15 if name.present?
    new_ranking += 20 if description.present?
    new_ranking += 15 if latitude.present? && longitude.present?
    new_ranking += 15 if url.present?
    new_ranking += 15 if video_id.present? && video_type.present?
    new_ranking += 20 if tags.present?

    # update the ranking if it has changed
    update_attribute(:ranking, new_ranking) if self.ranking != new_ranking
    return new_ranking
  end

  # set the windows for the channel
  def set_windows(new_channel = false)
    # check for video window
    if video_changed?
      update_video_window(true)
      update_video_window(false)
    end

    # check for location window
    if location_changed?
      update_location_window(true)
      update_location_window(false)
    end

    # add the status window no matter what, and only display it if it has values
    update_status_window(true)
    update_status_window(false)

    # update chart windows if this is a new channel or the fields have changed
    update_chart_windows if new_channel || fields_changed?
  end

  private

    # set the chart window; field_name should be a string like 'field4'
    def update_chart_window(field_name, private_flag)
      field_number = field_name.last.to_i

      # get the chart window
      window = self.windows.where(window_type: 'chart', content_id: field_number, private_flag: private_flag).first

      # if there is no chart window for this field, add a default one
      if window.blank?
        window = Window.new(window_type: 'chart', position: 0, col: 0, title: 'window_field_chart',
          name: field_name, content_id: field_number, private_flag: private_flag)
      end

      # set the options if they don't already exist
      window.options ||= "&results=60&dynamic=true"
      # associate the window with the channel
      self.windows.push window
      # set the html
      window.html = "<iframe id=\"iframe#{window.id}\" width=\"450\" height=\"260\" style=\"border: 1px solid #cccccc;\" src=\"/channels/#{self.id}/charts/#{field_number.to_s}?width=450&height=260::OPTIONS::\" ></iframe>"

      # save the window, and raise an exception if it fails
      if !window.save
        raise "The Window could not be saved"
      end
    end

    # set the default channel name
    def set_default_name
      update_attribute(:name, "#{I18n.t(:channel_default_name)} #{self.id}") if self.name.blank?
    end

end

