class ApiKeysController < ApplicationController
	before_filter :require_user, :set_channels_menu

	def index
		get_channel_data
		@read_keys = ApiKey.find(:all, :conditions => { :channel_id => @channel.id, :user_id => current_user.id, :write_flag => 0 })
	end

	def destroy
		@api_key = ApiKey.find_by_api_key(params[:api_key])
		@api_key.delete if @api_key.user_id == current_user.id
		redirect_to :back
	end

	def create
		@channel = Channel.find(params[:channel_id])
		# make sure channel belongs to current user
		check_permissions(@channel)

		@api_key = ApiKey.find(:first, :conditions => { :channel_id => @channel.id, :user_id => current_user.id, :write_flag => 1 } )

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
		redirect_to channel_api_keys_path(@channel.id) and return
	end

	def update
		@api_key = ApiKey.find_by_api_key(params[:api_key][:api_key])

		@api_key.note = params[:api_key][:note]
		@api_key.save if current_user.id == @api_key.user_id
		redirect_to channel_api_keys_path(@api_key.channel)
	end
end
