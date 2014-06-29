module ApiKeys
  def api_index(channel_id)
    if current_user && !current_user.channels.find_by_id(channel_id).nil?
      @channel = current_user.channels.find(channel_id)
    end
    if current_user.present? && @channel.present? && current_user.id == @channel.user_id
      @write_key = @channel.api_keys.write_keys.first
      @read_keys = @channel.api_keys.read_keys
    end
  end
end

