class AddHtmlToWindow < ActiveRecord::Migration
  def self.up
    add_column :windows, :html, :text
  end

  def self.down
    remove_column :windows, :html
  end
end
