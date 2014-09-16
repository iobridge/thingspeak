class CommentsController < ApplicationController
  before_filter :require_user

  def index
    redirect_to channel_path(:id => params[:channel_id], :public => true)
  end

  def create
    render :text => '' and return if params[:userlogin].length > 0

    @channel = Channel.find(params[:channel_id])
    @comment = @channel.comments.new
    @comment.user = current_user
    @comment.ip_address = get_header_value('X_REAL_IP')
    @comment.parent_id = params[:parent_id]
    @comment.body = params[:comment][:body].gsub(/<\/?[^>]*>/, '').gsub(/\n/, '<br />')
    # save comment
    if @comment.save
      flash[:notice] = "Thanks for adding a comment!"
    else
      flash[:alert] = "Comment can't be blank!"
    end
    redirect_to :back
  end

  def vote
    # make sure this is a post
    render :text => '' and return if !request.post?

    @comment = Comment.find(params[:id])
    @comment.flags += 1
    # delete if too many flags
    if (@comment.flags > 3)
      @comment.destroy
      render :text => ''
    # else save
    else
      @comment.save
      render :text => '1'
    end
  end

  def destroy
    comment = current_user.comments.find(params[:id]).destroy
    redirect_to :back
  end
end

