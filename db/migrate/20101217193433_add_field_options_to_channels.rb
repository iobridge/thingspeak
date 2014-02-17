class AddFieldOptionsToChannels < ActiveRecord::Migration
  def self.up
		add_column :channels, :options1, :text
		add_column :channels, :options2, :text
		add_column :channels, :options3, :text
		add_column :channels, :options4, :text
		add_column :channels, :options5, :text
		add_column :channels, :options6, :text
		add_column :channels, :options7, :text
		add_column :channels, :options8, :text
  end

  def self.down
		remove_column :channels, :options1
		remove_column :channels, :options2
		remove_column :channels, :options3
		remove_column :channels, :options4
		remove_column :channels, :options5
		remove_column :channels, :options6
		remove_column :channels, :options7
		remove_column :channels, :options8
  end
end
