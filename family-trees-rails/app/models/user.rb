class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # ActiveStorage attachment for profile picture
  has_one_attached :picture

  # Relationship associations
  has_many :relationships, dependent: :destroy
  has_many :inverse_relationships, class_name: 'Relationship',
                                    foreign_key: 'relative_id',
                                    dependent: :destroy

  # Direct family member associations
  has_many :relatives, through: :relationships
  has_many :inverse_relatives, through: :inverse_relationships, source: :user

  # Validations
  validate :bio_word_count

  # Helper method to get full name
  def full_name
    "#{first_name} #{last_name}".strip
  end

  # Helper method to get display name (falls back to email if name is blank)
  def display_name
    name = full_name
    name.present? ? name : email
  end

  # Check if user is deceased
  def deceased?
    date_died.present? && date_died <= Date.today
  end

  # Get current age or age at death
  def age
    return nil unless birthday.present?

    end_date = deceased? ? date_died : Date.today
    age = end_date.year - birthday.year
    age -= 1 if end_date < birthday + age.years
    age
  end

  # Family relationship query methods
  def parents(type: nil)
    relation = relationships.approved.parents.includes(:relative)
    relation = relation.where(relationship_type: type) if type
    relation.map(&:relative)
  end

  def children(type: nil)
    relation = relationships.approved.children.includes(:relative)
    relation = relation.where(relationship_type: type) if type
    relation.map(&:relative)
  end

  def spouses(include_ex: false)
    types = include_ex ? Relationship::SPOUSAL_TYPES : %w[spouse partner]
    relationships.approved.where(relationship_type: types).includes(:relative).map(&:relative)
  end

  def current_spouse
    relationships.approved.where(relationship_type: %w[spouse partner])
                 .active
                 .includes(:relative)
                 .first&.relative
  end

  def siblings(type: nil)
    relation = relationships.approved.siblings.includes(:relative)
    relation = relation.where(relationship_type: type) if type
    relation.map(&:relative)
  end

  # Get all family members (any relationship) - only approved
  # Uses DFS to find all connected family members through any degree of separation
  def all_family_members
    find_all_connected_family
  end

  # Get only direct family members (1 degree of separation)
  def direct_family_members
    approved_relatives = relationships.approved.includes(:relative).map(&:relative)
    approved_inverse_relatives = inverse_relationships.approved.includes(:user).map(&:user)
    (approved_relatives + approved_inverse_relatives).uniq
  end

  # Get all relationships for this user (both directions)
  def all_relationships
    Relationship.where('user_id = ? OR relative_id = ?', id, id)
  end

  # Check if user has a specific relationship with another user
  def related_to?(other_user, relationship_type = nil)
    query = relationships.approved.where(relative_id: other_user.id)
    query = query.where(relationship_type: relationship_type) if relationship_type
    query.exists?
  end

  # Get grandparents
  def grandparents
    parents.flat_map(&:parents).uniq
  end

  # Get grandchildren
  def grandchildren
    children.flat_map(&:children).uniq
  end

  # Get aunts and uncles (parents' siblings)
  def aunts_and_uncles
    parents.flat_map(&:siblings).uniq
  end

  # Get nieces and nephews (siblings' children)
  def nieces_and_nephews
    siblings.flat_map(&:children).uniq
  end

  # Get cousins (parents' siblings' children)
  def cousins
    aunts_and_uncles.flat_map(&:children).uniq
  end

  # Get all ancestors (recursive)
  def ancestors(generations: nil, current_generation: 0)
    return [] if generations && current_generation >= generations

    current_parents = parents
    return current_parents if current_parents.empty? || (generations && current_generation >= generations - 1)

    current_parents + current_parents.flat_map do |parent|
      parent.ancestors(generations: generations, current_generation: current_generation + 1)
    end.uniq
  end

  # Get all descendants (recursive)
  def descendants(generations: nil, current_generation: 0)
    return [] if generations && current_generation >= generations

    current_children = children
    return current_children if current_children.empty? || (generations && current_generation >= generations - 1)

    current_children + current_children.flat_map do |child|
      child.descendants(generations: generations, current_generation: current_generation + 1)
    end.uniq
  end

  private

  # DFS to find all connected family members (any degree of separation)
  # This traverses the entire family tree graph starting from the current user
  def find_all_connected_family(visited = Set.new)
    # Avoid infinite loops by tracking visited users
    return [] if visited.include?(self.id)
    visited.add(self.id)

    # Get all direct relatives (approved relationships only)
    direct_relatives = direct_family_members

    # Base case: if no relatives, return empty array
    return [] if direct_relatives.empty?

    # Recursive case: for each relative, find their family members too
    all_family = direct_relatives.dup

    direct_relatives.each do |relative|
      # Recursively find this relative's family members
      extended = relative.send(:find_all_connected_family, visited)
      all_family.concat(extended)
    end

    # Return unique family members (excluding self)
    all_family.uniq.reject { |member| member.id == self.id }
  end

  private

  def bio_word_count
    return if bio.blank?

    word_count = bio.split.size
    if word_count > 100
      errors.add(:bio, "is too long (maximum is 100 words, you have #{word_count} words)")
    end
  end
end
