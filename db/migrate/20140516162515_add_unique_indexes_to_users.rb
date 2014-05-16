class AddUniqueIndexesToUsers < ActiveRecord::Migration
  def change
    remove_index "users", ["email"]
    add_index "users", ["email"], unique: true
    remove_index "users", ["login"]
    add_index "users", ["login"], unique: true
    remove_index "users", ["authentication_token"]
    add_index "users", ["authentication_token"], unique: true
  end
end

