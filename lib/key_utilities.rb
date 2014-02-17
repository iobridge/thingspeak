module KeyUtilities

  # generates a database unique api key
  def generate_api_key(size = 16, type = 'channel')
    alphanumerics = ('0'..'9').to_a + ('A'..'Z').to_a
    new_key = (1..size).map {alphanumerics[Kernel.rand(36)]}.join

    # if key exists in database, regenerate key
    new_key = generate_api_key if type == 'channel' and ApiKey.find_by_api_key(new_key)
    new_key = generate_api_key(16, 'user') if type == 'user' and User.find_by_api_key(new_key)
    new_key = generate_api_key(16, 'twitter') if type == 'twitter' and TwitterAccount.find_by_api_key(new_key)
    new_key = generate_api_key(16, 'thinghttp') if type == 'thinghttp' and Thinghttp.find_by_api_key(new_key)
    new_key = generate_api_key(16, 'talkback') if type == 'talkback' and Talkback.find_by_api_key(new_key)
    return new_key
  end

end

