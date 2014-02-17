module ChannelsHelper
    include ApplicationHelper
  def auth_channels_path
    if current_user 
      '/channels' 
    else   
      '/channels/public' 
    end
  end
end

