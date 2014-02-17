class ChangeApiKeyLimit < ActiveRecord::Migration
  def change
    change_column :twitter_accounts, :api_key, :string, :limit => 17, :null => false
  end

end
