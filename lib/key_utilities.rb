module KeyUtilities
    
  # generates a database unique api key
  def generate_api_key(size = 16)
    alphanumerics = ('0'..'9').to_a + ('A'..'Z').to_a
    k = (0..(size - 1)).map {alphanumerics[Kernel.rand(36)]}.join
  
    # if key exists in database, regenerate key
    k = generate_api_key if ApiKey.find_by_api_key(k)
  
    # output the key
    k
  end
end
