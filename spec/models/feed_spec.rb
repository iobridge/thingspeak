require 'spec_helper'

describe Feed do

  it "should close the connection when an exception is raised" do
    # use a single connection for both queries
    connection = ActiveRecord::Base.connection

    # cause a proper timeout with the second argument to timeout()
    begin
      Timeout.timeout(1, Timeout::Error) do
        connection.execute("SELECT sleep(2)")
      end
    rescue Timeout::Error => e
    rescue => e
    end

    # capture the error message
    error_message = nil
    begin
      connection.execute("SELECT 1")
    rescue => e
      error_message = e.message
    end

    error_message.should eq("Mysql2::Error: closed MySQL connection: SELECT 1")

    # check the connection back in afterwards
    ActiveRecord::Base.connection_pool.checkin(connection)
  end

end

