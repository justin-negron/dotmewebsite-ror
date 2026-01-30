module RequestSpecHelper
  # Parse JSON response to Ruby hash
  def json
    JSON.parse(response.body, symbolize_names: true)
  end
  
  # Helper to get success data from response
  def json_data
    json[:data]
  end
  
  # Helper to get meta from response
  def json_meta
    json[:meta]
  end
  
  # Helper to get errors from response
  def json_errors
    json[:errors]
  end
end