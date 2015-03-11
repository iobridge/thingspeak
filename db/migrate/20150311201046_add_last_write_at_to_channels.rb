class AddLastWriteAtToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :last_write_at, :datetime
  end
end

