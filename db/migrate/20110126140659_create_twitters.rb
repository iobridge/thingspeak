class CreateTwitters < ActiveRecord::Migration
  def self.up
    create_table :twitters do |t|
      t.string :screen_name
      t.integer :user_id
      t.integer :twitter_id
      t.string :token
      t.string :secret

      t.timestamps
    end

		add_index :twitters, :user_id
		add_index :twitters, :twitter_id
  end

  def self.down
		remove_index :twitters, :user_id
		remove_index :twitters, :twitter_id		

    drop_table :twitters
  end
end
