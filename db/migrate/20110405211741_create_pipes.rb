class CreatePipes < ActiveRecord::Migration
  def self.up
    create_table :pipes do |t|
      t.string :name, :null => false
      t.string :url, :null => false
      t.string :slug, :null => false, :unique => true

      t.timestamps
    end

    add_index :pipes, :slug
  end

  def self.down
    remove_index :pipes, :slug

    drop_table :pipes
  end
end
