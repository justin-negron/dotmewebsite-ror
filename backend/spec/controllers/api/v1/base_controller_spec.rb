require 'rails_helper'

# Create a test controller to test base controller functionality
class TestController < Api::V1::BaseController
  def test_not_found
    raise ActiveRecord::RecordNotFound, 'Record not found'
  end
  
  def test_invalid_record
    contact = Contact.new
    contact.valid?
    raise ActiveRecord::RecordInvalid.new(contact)
  end
  
  def test_parameter_missing
    params.require(:missing_param)
  end
  
  def test_success
    render_success({ message: 'Success' }, status: :ok, meta: { page: 1 })
  end
  
  def test_error
    render_error('Error message', status: :bad_request, errors: ['Error 1', 'Error 2'])
  end
end

RSpec.describe Api::V1::BaseController, type: :controller do
  controller(TestController) do
    def index
      render json: { test: 'value' }
    end
  end
  
  before do
    routes.draw do
      get 'test_not_found' => 'test#test_not_found'
      get 'test_invalid_record' => 'test#test_invalid_record'
      get 'test_parameter_missing' => 'test#test_parameter_missing'
      get 'test_success' => 'test#test_success'
      get 'test_error' => 'test#test_error'
    end
  end
  
  describe 'error handling' do
    it 'handles RecordNotFound' do
      get :test_not_found
      
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:success]).to be false
      expect(json[:message]).to include('Record not found')
    end
    
    it 'handles RecordInvalid' do
      get :test_invalid_record
      
      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:success]).to be false
      expect(json[:message]).to eq('Validation failed')
      expect(json[:errors]).to be_an(Array)
    end
    
    it 'handles ParameterMissing' do
      get :test_parameter_missing
      
      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:success]).to be false
    end
  end
  
  describe 'render helpers' do
    it 'renders success response' do
      get :test_success
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:success]).to be true
      expect(json[:data][:message]).to eq('Success')
      expect(json[:meta][:page]).to eq(1)
    end
    
    it 'renders error response' do
      get :test_error
      
      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:success]).to be false
      expect(json[:message]).to eq('Error message')
      expect(json[:errors]).to eq(['Error 1', 'Error 2'])
    end
  end
end