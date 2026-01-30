require 'rails_helper'

RSpec.describe Project, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:description) }
  end
  
  describe 'scopes' do
    let!(:featured_project) { create(:project, :featured) }
    let!(:regular_project) { create(:project) }
    
    it 'returns only featured projects' do
      expect(Project.featured).to include(featured_project)
      expect(Project.featured).not_to include(regular_project)
    end
    
    it 'orders by display_order and created_at' do
      project1 = create(:project, display_order: 2)
      project2 = create(:project, display_order: 1)
      
      expect(Project.ordered.first).to eq(project2)
    end
  end
  
  describe '#tech_stack_list' do
    it 'returns comma-separated tech stack' do
      project = create(:project, tech_stack: ['Ruby', 'Rails', 'PostgreSQL'])
      expect(project.tech_stack_list).to eq('Ruby, Rails, PostgreSQL')
    end
  end
  
  describe 'display_order' do
    it 'auto-assigns display_order on create' do
      project = create(:project)
      expect(project.display_order).to be_present
    end
  end
end
