class ChangeChannelFieldsToStrings < ActiveRecord::Migration
  def self.up
		change_column :channels, :field1, :string
		change_column :channels, :field2, :string
		change_column :channels, :field3, :string
		change_column :channels, :field4, :string
		change_column :channels, :field5, :string
		change_column :channels, :field6, :string
		change_column :channels, :field7, :string
		change_column :channels, :field8, :string
		change_column :channels, :options1, :string
		change_column :channels, :options2, :string
		change_column :channels, :options3, :string
		change_column :channels, :options4, :string
		change_column :channels, :options5, :string
		change_column :channels, :options6, :string
		change_column :channels, :options7, :string
		change_column :channels, :options8, :string
  end

  def self.down
		change_column :channels, :field1, :text
		change_column :channels, :field2, :text
		change_column :channels, :field3, :text
		change_column :channels, :field4, :text
		change_column :channels, :field5, :text
		change_column :channels, :field6, :text
		change_column :channels, :field7, :text
		change_column :channels, :field8, :text
		change_column :channels, :options1, :text
		change_column :channels, :options2, :text
		change_column :channels, :options3, :text
		change_column :channels, :options4, :text
		change_column :channels, :options5, :text
		change_column :channels, :options6, :text
		change_column :channels, :options7, :text
		change_column :channels, :options8, :text
  end
end
