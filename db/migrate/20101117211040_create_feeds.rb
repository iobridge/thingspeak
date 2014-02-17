class CreateFeeds < ActiveRecord::Migration
  def self.up
    create_table :feeds do |t|
      t.integer :device_id
      t.text :raw_data
      t.text :data1
      t.text :data2
      t.text :data3
      t.text :data4
      t.text :data5
      t.text :data6
      t.text :data7
      t.text :data8

      t.timestamps
    end
  end

  def self.down
    drop_table :feeds
  end
end
