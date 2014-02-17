class CreateDailyFeeds < ActiveRecord::Migration
  def change
    create_table :daily_feeds do |t|
      t.integer :channel_id
      t.date :date
      t.string :calculation, :limit => 20
      t.string :result

      t.timestamps
    end

    add_index :daily_feeds, [:channel_id, :date]
  end
end

