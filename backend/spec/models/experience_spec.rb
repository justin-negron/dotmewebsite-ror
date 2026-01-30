require 'rails_helper'

RSpec.describe Experience, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:company) }
    it { should validate_presence_of(:position) }
    it { should validate_presence_of(:start_date) }
    
    it 'validates end_date is after start_date' do
      experience = build(:experience, start_date: Date.today, end_date: 1.year.ago)
      expect(experience).not_to be_valid
      expect(experience.errors[:end_date]).to include('must be after start date')
    end
  end
  
  describe 'scopes' do
    let!(:current_job) { create(:experience, :current, start_date: 1.year.ago) }
    let!(:past_job) { create(:experience, :past, start_date: 2.years.ago) }
    let!(:older_job) { create(:experience, :past, start_date: 3.years.ago) }
    
    it 'returns current experiences' do
      expect(Experience.current).to include(current_job)
      expect(Experience.current).not_to include(past_job)
    end
    
    it 'returns past experiences' do
      expect(Experience.past).to include(past_job)
      expect(Experience.past).not_to include(current_job)
    end
    
    it 'orders by start_date descending' do
      experiences = Experience.ordered.to_a
      expect(experiences.first).to eq(current_job)
      expect(experiences.second).to eq(past_job)
      expect(experiences.last).to eq(older_job)
    end
  end
  
  describe '#current?' do
    it 'returns true when end_date is nil' do
      experience = build(:experience, :current)
      expect(experience.current?).to be true
    end
    
    it 'returns false when end_date is present' do
      experience = build(:experience, :past)
      expect(experience.current?).to be false
    end
  end
  
  describe '#duration' do
    it 'returns formatted duration for current job' do
      experience = create(:experience, :current, start_date: Date.new(2023, 1, 1))
      expect(experience.duration).to include('January 2023')
      expect(experience.duration).to include('Present')
    end
    
    it 'returns formatted duration for past job' do
      experience = create(:experience, 
        start_date: Date.new(2020, 1, 1),
        end_date: Date.new(2022, 12, 31)
      )
      expect(experience.duration).to include('January 2020')
      expect(experience.duration).to include('December 2022')
    end
    
    it 'returns single month for same year start and end' do
      experience = create(:experience,
        start_date: Date.new(2023, 3, 1),
        end_date: Date.new(2023, 3, 31)
      )
      expect(experience.duration).to eq('March 2023')
    end
  end
  
  describe '#technologies_list' do
    it 'returns comma-separated technologies' do
      experience = create(:experience, technologies: ['Ruby', 'Rails', 'PostgreSQL'])
      expect(experience.technologies_list).to eq('Ruby, Rails, PostgreSQL')
    end
  end
  
  describe 'display_order' do
    it 'auto-assigns display_order on create' do
      experience = create(:experience)
      expect(experience.display_order).to be_present
    end
  end
end
