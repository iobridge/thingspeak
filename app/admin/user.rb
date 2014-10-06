ActiveAdmin.register User do
  require 'csv'

  filter :email
  filter :login
  filter :created_at

  permit_params :email, :login, :bio, :website

  index do
    column :id
    column :email
    column :login
    column :created_at
    actions
  end

  show do
    attributes_table do
      rows :id, :email, :login, :time_zone, :bio, :website, :created_at, :sign_in_count, :current_sign_in_at, :last_sign_in_at, :current_sign_in_ip, :last_sign_in_ip
    end
    panel 'Channels' do
      table_for user.channels do
        column :id
        column(:name) { |channel| link_to channel.name, channel }
      end
    end
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs :email, :login
    f.actions
  end

  # custom action for signups per day
  collection_action :signups, :method => :get, :format => :csv do
    @csv_headers = [:day, :signups]
    @days = User.signups_per_day
  end

  # custom action for emails list
  collection_action :emails, :method => :get do
    @users = User.all
  end

end

