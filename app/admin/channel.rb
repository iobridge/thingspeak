ActiveAdmin.register Channel do

  filter :name
  filter :description
  filter :created_at

  permit_params :name, :public_flag

  index do
    column :id
    column(:name) { |channel| link_to channel.name, channel }
    column(:user) { |channel| link_to channel.user.login, admin_user_path(channel.user) if channel.user.present? }
    column :public_flag
    column :created_at
    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs :name, :public_flag
    f.actions
  end

end

