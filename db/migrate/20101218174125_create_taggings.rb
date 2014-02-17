class CreateTaggings < ActiveRecord::Migration
  def self.up
    create_table :taggings do |t|
      t.integer :tag_id
      t.integer :channel_id

      t.timestamps
    end
		add_index :taggings, :tag_id
		add_index :taggings, :channel_id
  end

  def self.down
    drop_table :taggings
  end
end
