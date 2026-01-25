class Project < ApplicationRecord
  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true
  validates :github_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }
  validates :live_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }
  validates :display_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :featured, -> { where(featured: true) }
  scope :ordered, -> { order(display_order: :asc, created_at: :desc) }
  scope :by_tech, ->(tech) { where("? = ANY(tech_stack)", tech) }

  # Callbacks
  before_validation :set_display_order, on: :create

  # Instance methods
  def tech_stack_list
    tech_stack.join(", ")
  end

  private

  def set_display_order
    self.display_order ||= Project.maximum(:display_order).to_i + 1
  end
end