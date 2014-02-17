class AddRankingToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :ranking, :integer
  end

  def self.down
    remove_column :channels, :ranking
  end
end
