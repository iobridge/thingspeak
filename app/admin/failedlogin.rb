ActiveAdmin.register Failedlogin do
  menu :parent => "Others"
  actions :all, :except => [:edit]

  filter :login
  filter :password
  filter :created_at

  index do
    column :id
    column :login
    column :password
    column :ip_address
    column :created_at
    default_actions
  end

end

