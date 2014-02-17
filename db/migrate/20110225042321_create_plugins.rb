class CreatePlugins < ActiveRecord::Migration
  def self.up
    create_table :plugins do |t|
      t.string :name
      t.integer :user_id
      t.text :html
      t.text :css
      t.text :js

      t.timestamps
    end

		add_index :plugins, :user_id
  end

  def self.down
		remove_index :plugins, :user_id

    drop_table :plugins
  end
end
