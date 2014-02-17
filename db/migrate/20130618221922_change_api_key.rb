class ChangeApiKey < ActiveRecord::Migration
  def change
    change_column :twitter_accounts, :api_key, :string
  end

end
