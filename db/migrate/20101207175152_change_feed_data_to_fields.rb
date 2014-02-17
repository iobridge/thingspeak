class ChangeFeedDataToFields < ActiveRecord::Migration
  def self.up
		rename_column :feeds, :data1, :field1
		rename_column :feeds, :data2, :field2
		rename_column :feeds, :data3, :field3
		rename_column :feeds, :data4, :field4
		rename_column :feeds, :data5, :field5
		rename_column :feeds, :data6, :field6
		rename_column :feeds, :data7, :field7
		rename_column :feeds, :data8, :field8
  end

  def self.down
		rename_column :feeds, :field1, :data1
		rename_column :feeds, :field2, :data2
		rename_column :feeds, :field3, :data3
		rename_column :feeds, :field4, :data4
		rename_column :feeds, :field5, :data5
		rename_column :feeds, :field6, :data6
		rename_column :feeds, :field7, :data7
		rename_column :feeds, :field8, :data8
  end
end
