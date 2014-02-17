class TagsController < ApplicationController
  def index

    render 'show' and return if params[:channel_id].nil?
    
    channel = Channel.find(params[:channel_id])
    if current_user && channel.nil?
      tag = Tag.find_by_name(params[:id], :include => :channels, :conditions => ['channels.public_flag = true OR channels.user_id = ?', current_user.id])
    else
      channels = []
      channel.tags.each do |tag|
        channels << tag.channel_ids
      end
      
      channels = channels.flatten.uniq

    end
    redirect_to public_channels_path(:channel_ids => channels)
  end

  def create
    redirect_to tag_path(params[:tag][:name])
  end

  def show
    # if user is logged in, search their channels also
    if current_user
      tag = Tag.find_by_name(params[:id], :include => :channels, :conditions => ['channels.public_flag = true OR channels.user_id = ?', current_user.id])
      # else only search public channels
    else
      tag = Tag.find_by_name(params[:id], :include => :channels, :conditions => ['channels.public_flag = true'])
    end

    @results = tag.channels if tag
  end

end
