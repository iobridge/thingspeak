class AddNoteToApiKeys < ActiveRecord::Migration
  def self.up
		add_column :api_keys, :note, :string
  end

  def self.down
		remove_column :api_keys, :note
  end
end
