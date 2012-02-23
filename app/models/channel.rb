class Channel < ActiveRecord::Base
  include KeyUtilities
  
  belongs_to :user
	has_many :feeds
	has_many :api_keys

  attr_readonly :created_at
  attr_protected :user_id, :last_entry_id

  after_create :set_initial_default_name
  before_validation :set_default_name
  after_destroy :delete_feeds
  
  validates :name, :presence => true, :on => :update

  def add_write_api_key
    write_key = self.api_keys.new
    write_key.user = self.user
    write_key.write_flag = true
    write_key.api_key = generate_api_key
    write_key.save
  end

  def field_label(field_number)
    self.attributes["field#{field_number}"]
  end
  
  def delete_feeds
    Feed.delete_all(["channel_id = ?", self.id])    
  end

private

  def set_default_name    
    self.name = "#{I18n.t(:channel_default_name)} #{self.id}" if self.name.blank?
  end

  def set_initial_default_name
    update_attribute(:name, "#{I18n.t(:channel_default_name)} #{self.id}")
  end

end






# == Schema Information
#
# Table name: channels
#
#  id            :integer(4)      not null, primary key
#  user_id       :integer(4)
#  name          :string(255)
#  description   :string(255)
#  latitude      :decimal(15, 10)
#  longitude     :decimal(15, 10)
#  field1        :text
#  field2        :text
#  field3        :text
#  field4        :text
#  field5        :text
#  field6        :text
#  field7        :text
#  field8        :text
#  scale1        :integer(4)
#  scale2        :integer(4)
#  scale3        :integer(4)
#  scale4        :integer(4)
#  scale5        :integer(4)
#  scale6        :integer(4)
#  scale7        :integer(4)
#  scale8        :integer(4)
#  created_at    :datetime
#  updated_at    :datetime
#  elevation     :string(255)
#  last_entry_id :integer(4)
#  public_flag   :boolean(1)      default(FALSE)
#

