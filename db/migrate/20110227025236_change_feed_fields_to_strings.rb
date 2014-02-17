class ChangeFeedFieldsToStrings < ActiveRecord::Migration
  def self.up
		change_column :feeds, :field1, :string
		change_column :feeds, :field2, :string
		change_column :feeds, :field3, :string
		change_column :feeds, :field4, :string
		change_column :feeds, :field5, :string
		change_column :feeds, :field6, :string
		change_column :feeds, :field7, :string
		change_column :feeds, :field8, :string
  end

  def self.down
		change_column :feeds, :field1, :text
		change_column :feeds, :field2, :text
		change_column :feeds, :field3, :text
		change_column :feeds, :field4, :text
		change_column :feeds, :field5, :text
		change_column :feeds, :field6, :text
		change_column :feeds, :field7, :text
		change_column :feeds, :field8, :text
  end
end
