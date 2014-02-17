class CreateWatchings < ActiveRecord::Migration
  def self.up
    create_table :watchings do |t|
      t.integer :user_id
      t.integer :channel_id

      t.timestamps
    end

    add_index :watchings, [:user_id, :channel_id]
  end

  def self.down
    remove_index :watchings, [:user_id, :channel_id]

    drop_table :watchings
  end
end
