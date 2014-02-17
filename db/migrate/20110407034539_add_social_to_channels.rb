class AddSocialToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :social, :boolean, :default => 0
    add_column :channels, :slug, :string

    add_index :channels, :slug
  end

  def self.down
    remove_index :channels, :slug

    remove_column :channels, :slug
    remove_column :channels, :social
  end
end
