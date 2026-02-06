require 'rails_helper'

RSpec.describe ExperienceResource do
  describe 'serialization' do
    it 'formats start_date when present' do
      experience = create(:experience, start_date: Date.new(2023, 1, 15))
      result = ExperienceResource.new(experience).to_h

      expect(result["start_date"]).to eq('2023-01-15')
    end

    it 'handles nil start_date' do
      experience = build(:experience, start_date: nil)
      result = ExperienceResource.new(experience).to_h

      expect(result["start_date"]).to be_nil
    end

    it 'formats end_date when present' do
      experience = create(:experience, end_date: Date.new(2024, 12, 31))
      result = ExperienceResource.new(experience).to_h

      expect(result["end_date"]).to eq('2024-12-31')
    end

    it 'handles nil end_date for current job' do
      experience = create(:experience, :current, end_date: nil)
      result = ExperienceResource.new(experience).to_h

      expect(result["end_date"]).to be_nil
      expect(result["current"]).to be true
    end

    it 'formats created_at when present' do
      experience = create(:experience)
      result = ExperienceResource.new(experience).to_h

      expect(result["created_at"]).to match(/\d{4}-\d{2}-\d{2}T/)
    end

    it 'handles nil created_at' do
      experience = build(:experience, created_at: nil)
      result = ExperienceResource.new(experience).to_h

      expect(result["created_at"]).to be_nil
    end

    it 'formats updated_at when present' do
      experience = create(:experience)
      result = ExperienceResource.new(experience).to_h

      expect(result["updated_at"]).to match(/\d{4}-\d{2}-\d{2}T/)
    end

    it 'handles nil updated_at' do
      experience = build(:experience, updated_at: nil)
      result = ExperienceResource.new(experience).to_h

      expect(result["updated_at"]).to be_nil
    end
  end
end
