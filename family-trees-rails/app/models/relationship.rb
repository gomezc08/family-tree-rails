class Relationship < ApplicationRecord
  # Associations
  belongs_to :user, class_name: 'User'
  belongs_to :relative, class_name: 'User'
  belongs_to :initiated_by, class_name: 'User', optional: true

  # Relationship type constants
  PARENT_CHILD_TYPES = %w[parent child].freeze
  BIOLOGICAL_PARENT_CHILD = %w[biological_parent biological_child].freeze
  ADOPTIVE_PARENT_CHILD = %w[adoptive_parent adoptive_child].freeze
  STEP_PARENT_CHILD = %w[step_parent step_child].freeze
  SPOUSAL_TYPES = %w[spouse ex_spouse partner ex_partner].freeze
  SIBLING_TYPES = %w[sibling half_sibling step_sibling].freeze

  ALL_TYPES = (
    PARENT_CHILD_TYPES +
    BIOLOGICAL_PARENT_CHILD +
    ADOPTIVE_PARENT_CHILD +
    STEP_PARENT_CHILD +
    SPOUSAL_TYPES +
    SIBLING_TYPES
  ).freeze

  # Status constants
  STATUSES = %w[pending approved rejected].freeze

  # Validations
  validates :relationship_type, presence: true, inclusion: { in: ALL_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :user_id, presence: true
  validates :relative_id, presence: true
  validate :cannot_be_own_relative
  validate :end_date_after_start_date
  validate :unique_relationship_per_type

  # Callbacks
  before_validation :set_initiated_by, on: :create
  after_create :create_reciprocal_relationship
  after_create :infer_additional_relationships
  after_destroy :destroy_reciprocal_relationship
  after_update :update_reciprocal_relationship

  # Scopes
  scope :parents, -> { where(relationship_type: parent_types) }
  scope :children, -> { where(relationship_type: child_types) }
  scope :spouses, -> { where(relationship_type: SPOUSAL_TYPES) }
  scope :siblings, -> { where(relationship_type: SIBLING_TYPES) }
  scope :active, -> { where(end_date: nil).or(where('end_date > ?', Date.today)) }
  scope :ended, -> { where('end_date <= ?', Date.today) }
  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :rejected, -> { where(status: 'rejected') }

  # Class methods
  def self.parent_types
    PARENT_CHILD_TYPES.select { |t| t.include?('parent') } +
      BIOLOGICAL_PARENT_CHILD.select { |t| t.include?('parent') } +
      ADOPTIVE_PARENT_CHILD.select { |t| t.include?('parent') } +
      STEP_PARENT_CHILD.select { |t| t.include?('parent') }
  end

  def self.child_types
    PARENT_CHILD_TYPES.select { |t| t.include?('child') } +
      BIOLOGICAL_PARENT_CHILD.select { |t| t.include?('child') } +
      ADOPTIVE_PARENT_CHILD.select { |t| t.include?('child') } +
      STEP_PARENT_CHILD.select { |t| t.include?('child') }
  end

  # Instance methods
  def active?
    end_date.nil? || end_date > Date.today
  end

  def pending?
    status == 'pending'
  end

  def approved?
    status == 'approved'
  end

  def rejected?
    status == 'rejected'
  end

  def approve!
    transaction do
      update!(status: 'approved')
      # Approve the reciprocal relationship as well (skip callbacks to avoid infinite loop)
      reciprocal = find_reciprocal
      reciprocal&.update_columns(status: 'approved', updated_at: Time.current)
    end
  end

  def reject!
    transaction do
      update!(status: 'rejected')
      # Reject the reciprocal relationship as well (skip callbacks to avoid infinite loop)
      reciprocal = find_reciprocal
      reciprocal&.update_columns(status: 'rejected', updated_at: Time.current)
    end
  end

  def reciprocal_type
    case relationship_type
    when 'parent', 'biological_parent', 'adoptive_parent', 'step_parent'
      relationship_type.gsub('parent', 'child')
    when 'child', 'biological_child', 'adoptive_child', 'step_child'
      relationship_type.gsub('child', 'parent')
    when 'spouse', 'ex_spouse', 'partner', 'ex_partner'
      relationship_type
    when *SIBLING_TYPES
      relationship_type
    else
      relationship_type
    end
  end

  def display_type
    relationship_type.humanize.titleize
  end

  private

  def set_initiated_by
    # Set initiated_by_id to the user who is creating this relationship
    # This is only set on the initial creation, not for reciprocals
    self.initiated_by_id ||= user_id
  end

  def cannot_be_own_relative
    if user_id == relative_id
      errors.add(:relative_id, "cannot be the same as user")
    end
  end

  def end_date_after_start_date
    if start_date.present? && end_date.present? && end_date < start_date
      errors.add(:end_date, "must be after start date")
    end
  end

  def unique_relationship_per_type
    existing = Relationship.where(
      user_id: user_id,
      relative_id: relative_id,
      relationship_type: relationship_type
    ).where.not(id: id)

    if existing.exists?
      errors.add(:base, "This relationship already exists")
    end
  end

  def create_reciprocal_relationship
    return if reciprocal_exists?

    Relationship.create!(
      user_id: relative_id,
      relative_id: user_id,
      relationship_type: reciprocal_type,
      start_date: start_date,
      end_date: end_date,
      notes: notes,
      status: status,
      initiated_by_id: initiated_by_id  # Preserve who initiated the request
    )
  rescue ActiveRecord::RecordInvalid
    # Reciprocal might already exist, silently continue
  end

  def destroy_reciprocal_relationship
    reciprocal = find_reciprocal
    reciprocal&.destroy
  end

  def update_reciprocal_relationship
    reciprocal = find_reciprocal
    if reciprocal
      # Use update_columns to skip callbacks and avoid infinite loop
      reciprocal.update_columns(
        relationship_type: reciprocal_type,
        start_date: start_date,
        end_date: end_date,
        notes: notes,
        status: status,
        updated_at: Time.current
      )
    end
  end

  def find_reciprocal
    Relationship.find_by(
      user_id: relative_id,
      relative_id: user_id,
      relationship_type: reciprocal_type
    )
  end

  def reciprocal_exists?
    find_reciprocal.present?
  end

  def infer_additional_relationships
    # Only infer relationships when:
    # 1. A child is declaring their parent (type: parent, initiated by the user/child)
    # 2. This ensures we infer from the child's perspective, not the parent's
    #
    # We DON'T want to infer when:
    # - A parent declares their child (type: child, initiated by the user/parent)
    # - This would create incorrect sibling relationships
    if relationship_type.include?('parent') && initiated_by_id == user_id
      infer_from_child_perspective
    end
  end

  def infer_from_child_perspective
    # The current relationship is: self.user (child) -> self.relative (parent)
    # This method is called when relationship_type includes 'parent' and user initiated it
    child = user
    parent = relative

    # 1. Check if parent has a spouse - if yes, create step_parent relationship
    infer_parent_spouse_relationship(child, parent)

    # 2. Check if parent has other children - if yes, create sibling relationships
    infer_sibling_relationships(child, parent)
  end

  def infer_parent_spouse_relationship(child, parent)
    # Find the parent's current spouse/partner
    spouse = parent.current_spouse

    return unless spouse
    return if child == spouse # Safety check

    # Check if relationship already exists
    existing = Relationship.find_by(
      user_id: child.id,
      relative_id: spouse.id,
      relationship_type: 'step_parent'
    )

    return if existing

    # Create step_parent relationship from child to parent's spouse
    # Auto-generated relationships should be approved and initiated by the system
    Relationship.create!(
      user_id: child.id,
      relative_id: spouse.id,
      relationship_type: 'step_parent',
      start_date: start_date,
      notes: "Auto-generated: #{parent.display_name}'s spouse",
      status: 'approved',
      initiated_by_id: initiated_by_id  # Preserve the original initiator
    )
  rescue ActiveRecord::RecordInvalid => e
    # Log or handle error if needed, but don't fail the original relationship creation
    Rails.logger.info "Could not create inferred step_parent relationship: #{e.message}"
  end

  def infer_sibling_relationships(child, parent)
    # Find all other children of this parent
    other_children_relationships = Relationship.where(
      user_id: parent.id,
      relationship_type: self.class.child_types
    ).where.not(relative_id: child.id)

    other_children = other_children_relationships.map(&:relative)

    other_children.each do |sibling|
      next if child == sibling # Safety check

      # Check if sibling relationship already exists
      existing = Relationship.find_by(
        user_id: child.id,
        relative_id: sibling.id,
        relationship_type: 'sibling'
      )

      next if existing

      # Determine sibling type based on parent relationship type
      sibling_type = if relationship_type == 'step_child'
                       'step_sibling'
                     elsif relationship_type.include?('biological')
                       'sibling' # Full biological siblings
                     else
                       'sibling' # Default to sibling
                     end

      # Create sibling relationship
      # Auto-generated relationships should be approved and initiated by the system
      Relationship.create!(
        user_id: child.id,
        relative_id: sibling.id,
        relationship_type: sibling_type,
        start_date: start_date,
        notes: "Auto-generated: shares parent #{parent.display_name}",
        status: 'approved',
        initiated_by_id: initiated_by_id  # Preserve the original initiator
      )
    rescue ActiveRecord::RecordInvalid => e
      # Log or handle error if needed
      Rails.logger.info "Could not create inferred sibling relationship: #{e.message}"
    end
  end
end
