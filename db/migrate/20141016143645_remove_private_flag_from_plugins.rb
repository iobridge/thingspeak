class RemovePrivateFlagFromPlugins < ActiveRecord::Migration
  def change
    remove_column :plugins, :private_flag
  end
end

