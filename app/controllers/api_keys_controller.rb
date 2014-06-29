class ApiKeysController < ApplicationController
  include KeyUtilities, ApiKeys

  before_filter :require_user, :set_channels_menu

  def index
    api_index params[:channel_id]
    respond_with_error(:error_auth_required) and return if @channel.blank?
  end

  def destroy
    current_user.api_keys.find_by_api_key(params[:id].to_s).try(:destroy)
    redirect_to :back
  end

  def create
    @channel = current_user.channels.find(params[:channel_id])
    @api_key = @channel.api_keys.write_keys.first

    # if no api key found or read api key
    if (@api_key.nil? || params[:write] == '0')
      @api_key = ApiKey.new
      @api_key.channel_id = @channel.id
      @api_key.user_id = current_user.id
      @api_key.write_flag = params[:write]
    end

    # set new api key and save
    @api_key.api_key = generate_api_key
    @api_key.save

    # redirect
#    redirect_to channel_api_keys_path(@channel.id)
    redirect_to channel_path(@channel.id, :anchor => "apikeys")
  end

  def update
    @api_key = current_user.api_keys.find_by_api_key(params[:id].to_s)
    @api_key.update_attributes(api_key_params)
    redirect_to :back
  end

  private

    # only allow these params
    def api_key_params
      params.require(:api_key).permit(:note)
    end

end

