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

    it 'leaves experiences that have not started out of current' do
      upcoming = create(:experience, :current, start_date: 1.year.from_now.to_date)
      expect(Experience.current).not_to include(upcoming)
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

    it 'returns false when it has not started yet' do
      experience = build(:experience, :current, start_date: 1.month.from_now.to_date)
      expect(experience.current?).to be false
    end
  end

  describe '#upcoming?' do
    it 'is true only when start_date is in the future' do
      expect(build(:experience, start_date: 1.day.from_now.to_date, end_date: nil)).to be_upcoming
      expect(build(:experience, :current, start_date: Date.current)).not_to be_upcoming
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

    context 'when it has not started yet' do
      around { |example| travel_to(Date.new(2026, 10, 11)) { example.run } }

      {
        Date.new(2027, 8, 15) => 'Incoming Fall 2027',
        Date.new(2027, 1, 10) => 'Incoming Spring 2027',
        Date.new(2027, 6, 1) => 'Incoming Summer 2027'
      }.each do |start_date, label|
        it "returns #{label.inspect} for a start on #{start_date}" do
          expect(build(:experience, :current, start_date: start_date).duration).to eq(label)
        end
      end
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
