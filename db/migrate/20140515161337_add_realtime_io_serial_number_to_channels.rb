class AddRealtimeIoSerialNumberToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :realtime_io_serial_number, :string, :limit => 36
    add_index :channels, :realtime_io_serial_number
  end
end

