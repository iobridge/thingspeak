class AddApiKeyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :api_key, :string, :limit => 16
  end
end

