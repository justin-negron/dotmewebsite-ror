module RequestSpecHelper
  # Parse JSON response to Ruby hash
  def json
    JSON.parse(response.body, symbolize_names: true)
  end
  
  # Helper to get success data from response
  def json_data
    data = json[:data]
    
    # Handle the ActiveModelSerializers wrapping
    # Response format: { success: true, data: { resource_name: [...] }, meta: {} }
    if data.is_a?(Hash) && data.size == 1
      # Extract the inner value (the actual data array or object)
      data.values.first
    else
      data
    end
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