class SetRankingsForChannels < ActiveRecord::Migration
  def change
    Channel.find_each do |channel|
      channel.set_ranking
    end
  end
end

