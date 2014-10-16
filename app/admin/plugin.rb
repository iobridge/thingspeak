ActiveAdmin.register Plugin do

  filter :name
  filter :created_at

  permit_params :name, :html, :css, :js, :public_flag

  index do
    column :id
    column(:user) { |object| link_to object.user.login, admin_user_path(object.user) if object.user.present? }
    column :name
    column :public_flag
    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs :name, :html, :css, :js, :public_flag
    f.actions
  end

end

