class AddUserAgentToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :user_agent, :string
  end
end

