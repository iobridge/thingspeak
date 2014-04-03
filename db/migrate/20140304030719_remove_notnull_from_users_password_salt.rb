class RemoveNotnullFromUsersPasswordSalt < ActiveRecord::Migration
  def change
    change_column :users, :password_salt, :string, :null => true
  end
end

