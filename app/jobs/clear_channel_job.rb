class ClearChannelJob
  @queue = :clear_channel

  def self.perform(channel_id)
    # delete feeds
    Feed.delete_in_batches(channel_id)
    DailyFeed.delete_all(["channel_id = ?", channel_id])
    if channel = Channel.find(channel_id)
      channel.last_entry_id = nil
      channel.clearing = false
      channel.save
    end
  end
end

