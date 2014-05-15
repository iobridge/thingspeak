class StreamController < ApplicationController
  include ActionController::Live
  require 'csv'

  def channel_feed
    channel = Channel.find(params[:id])
    api_key = ApiKey.find_by_api_key(get_apikey)

    # output proper http response if error
    render :text => '-1', :status => 400 and return if !channel_permission?(channel, api_key)

    # set the attachment headers
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = 'attachment; filename=feeds.csv'

    # get the feed headers
    csv_headers = Feed.select_options(channel, params)

    # write the headers row
    response.stream.write "#{CSV.generate_line(csv_headers)}"

    # set loop variables
    batch_size = 1000
    last_entry_id = channel.last_entry_id
    current_entry_id = 0

    # while there are still entries to process
    while current_entry_id < last_entry_id
      # variable to hold the streaming output for this batch
      batch_output = ""

      # get the feeds
      feeds = Feed.where(:channel_id => channel.id).where("entry_id > ? AND entry_id <= ?", current_entry_id, current_entry_id + batch_size).order('entry_id asc').limit(batch_size)

      # set the current entry id
      current_entry_id += batch_size

      # for each feed, add the data according to the csv_headers
      feeds.each do |feed|
        row = []
        csv_headers.each { |attr| row.push(feed.send(attr)) }
        batch_output += CSV.generate_line(row)
      end

      # write the output for this batch
      response.stream.write batch_output if batch_output.present?

      # add a slight delay between database queries
      sleep 0.1
    end
  ensure
    response.stream.close
  end

  def stream_example
    # get the channel
    #channel = Channel.find(params[:channel_id])

    # stream the response
    #response.headers['Content-Type'] = 'text/csv'
    #response.headers['Content-Disposition'] = 'attachment; filename=feeds.csv'
    20.times {
      response.stream.write "hello world\n"
      sleep 1
    }
  ensure
    response.stream.close
  end

  def stream_chunked_example
    #response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = 'attachment; filename=feeds.csv'
    response.headers['Transfer-Encoding'] = 'chunked'
    10.times {
      response.stream.write "4\n" # size must be in hex format?
      response.stream.write "hel\n\n"
      sleep 1
    }
    response.stream.write "0\n\n"
  ensure
    response.stream.close
  end

end

