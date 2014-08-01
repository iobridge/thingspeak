class ModifyRankingIndexOnChannels < ActiveRecord::Migration
  def change
    remove_index :channels, :ranking
    add_index :channels, [:ranking, :updated_at]
  end
end

