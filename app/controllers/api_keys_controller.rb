class ApiKeysController < ApplicationController
  include KeyUtilities

	before_filter :require_user, :set_channels_menu

	def index
		@channel = current_user.channels.find(params[:channel_id])
		@write_key = @channel.api_keys.write_keys.first
		@read_keys = @channel.api_keys.read_keys
	end

	def destroy
		current_user.api_keys.find_by_api_key(params[:id]).try(:destroy)
		redirect_to :back
	end

	def create
		@channel = current_user.channels.find(params[:channel_id])
		@api_key = @channel.api_keys.write_keys.first

		# if no api key found or read api key
		if (@api_key.nil? or params[:write] == '0')
			@api_key = ApiKey.new
			@api_key.channel_id = @channel.id
			@api_key.user_id = current_user.id
			@api_key.write_flag = params[:write]
		end

		# set new api key and save
		@api_key.api_key = generate_api_key
		@api_key.save

		# redirect
		redirect_to channel_api_keys_path(@channel)
	end

	def update
		@api_key = current_user.api_keys.find_by_api_key(params[:id])
		@api_key.update_attributes(params[:api_key])
		redirect_to :back
	end
end
