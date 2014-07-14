ActiveAdmin.register_page "Dashboard" do

  menu priority: 1, label: "Dashboard"

  content title: "Dashboard" do
    columns do

      column do
        panel "Stats" do
          para "Total Users: #{User.all.count}"
          para "Total Channels: #{Channel.all.count}"
        end
      end

      column do
        panel "Recent Channels" do
          ul do
            Channel.all.order("created_at desc").limit(5).map do |channel|
              li link_to(channel.name, admin_channel_path(channel))
            end
          end
        end
      end

    end
  end # content
end

