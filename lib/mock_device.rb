# mocks a device by sending random data to a channel
# usage: ruby mock_device.rb API_KEY
# example: ruby lib/mock_device.rb XN2D3V54EWEQBKO6

require 'net/http'

# get the api key from the arguments
api_key = ARGV[0]

# domain
domain = URI.parse("http://localhost:3000/")

# start the data randomly
data = rand(1000)/10.to_f

# infinite loop
while true do
  # drift the data points
  data += rand(-5.to_f..5.to_f)
  data = data.round(1)
  puts "update: #{data}"

  # send the data
  full_url = "#{domain}update?api_key=#{api_key}&field1=#{data}"
  Net::HTTP.get(URI.parse(full_url))

  # wait 15 seconds before POSTing again
  sleep 15
end

