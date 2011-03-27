# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20101210151518) do

  create_table "api_keys", :force => true do |t|
    t.string   "api_key",    :limit => 16
    t.integer  "channel_id"
    t.integer  "user_id"
    t.boolean  "write_flag",               :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "note"
  end

  add_index "api_keys", ["api_key"], :name => "index_api_keys_on_api_key", :unique => true
  add_index "api_keys", ["channel_id"], :name => "index_api_keys_on_channel_id"

  create_table "channels", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "description"
    t.decimal  "latitude",      :precision => 15, :scale => 10
    t.decimal  "longitude",     :precision => 15, :scale => 10
    t.text     "field1"
    t.text     "field2"
    t.text     "field3"
    t.text     "field4"
    t.text     "field5"
    t.text     "field6"
    t.text     "field7"
    t.text     "field8"
    t.integer  "scale1"
    t.integer  "scale2"
    t.integer  "scale3"
    t.integer  "scale4"
    t.integer  "scale5"
    t.integer  "scale6"
    t.integer  "scale7"
    t.integer  "scale8"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "elevation"
    t.integer  "last_entry_id"
    t.boolean  "public_flag",                                   :default => false
  end

  create_table "feeds", :force => true do |t|
    t.integer  "channel_id"
    t.text     "raw_data"
    t.text     "field1"
    t.text     "field2"
    t.text     "field3"
    t.text     "field4"
    t.text     "field5"
    t.text     "field6"
    t.text     "field7"
    t.text     "field8"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "entry_id"
    t.string   "status"
  end

  add_index "feeds", ["channel_id"], :name => "index_feeds_on_channel_id"

  create_table "users", :force => true do |t|
    t.string   "login",             :null => false
    t.string   "email",             :null => false
    t.string   "crypted_password",  :null => false
    t.string   "password_salt",     :null => false
    t.string   "persistence_token", :null => false
    t.string   "perishable_token",  :null => false
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip"
    t.string   "last_login_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "time_zone"
  end

end
