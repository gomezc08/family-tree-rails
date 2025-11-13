require 'rails_helper'

RSpec.describe Relationship, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:relative) }
  end

  describe 'validations' do
    it { should validate_presence_of(:relationship_type) }
    it { should validate_inclusion_of(:relationship_type).in_array(Relationship::ALL_TYPES) }

    it 'validates that user cannot be their own relative' do
      user = create(:user)
      relationship = build(:relationship, user: user, relative: user)
      expect(relationship).not_to be_valid
      expect(relationship.errors[:relative_id]).to include("cannot be the same as user")
    end

    it 'validates that end_date is after start_date' do
      relationship = build(:relationship, start_date: Date.today, end_date: 1.day.ago)
      expect(relationship).not_to be_valid
      expect(relationship.errors[:end_date]).to include("must be after start date")
    end

    it 'validates uniqueness of relationship per type' do
      user = create(:user)
      relative = create(:user)
      create(:relationship, user: user, relative: relative, relationship_type: 'parent')

      duplicate = build(:relationship, user: user, relative: relative, relationship_type: 'parent')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:base]).to include("This relationship already exists")
    end
  end

  describe 'callbacks' do
    describe '#create_reciprocal_relationship' do
      it 'creates reciprocal relationship for parent-child' do
        parent = create(:user)
        child = create(:user)

        relationship = create(:relationship, user: parent, relative: child, relationship_type: 'parent')

        reciprocal = Relationship.find_by(user: child, relative: parent, relationship_type: 'child')
        expect(reciprocal).to be_present
      end

      it 'creates reciprocal relationship for spouse' do
        spouse1 = create(:user)
        spouse2 = create(:user)

        relationship = create(:relationship, user: spouse1, relative: spouse2, relationship_type: 'spouse')

        reciprocal = Relationship.find_by(user: spouse2, relative: spouse1, relationship_type: 'spouse')
        expect(reciprocal).to be_present
      end
    end

    describe '#destroy_reciprocal_relationship' do
      it 'destroys reciprocal relationship when relationship is destroyed' do
        parent = create(:user)
        child = create(:user)

        relationship = create(:relationship, user: parent, relative: child, relationship_type: 'parent')
        reciprocal = Relationship.find_by(user: child, relative: parent, relationship_type: 'child')

        relationship.destroy

        expect(Relationship.find_by(id: reciprocal.id)).to be_nil
      end
    end
  end

  describe '#active?' do
    it 'returns true when end_date is nil' do
      relationship = create(:relationship, end_date: nil)
      expect(relationship.active?).to be true
    end

    it 'returns true when end_date is in the future' do
      relationship = create(:relationship, end_date: 1.day.from_now)
      expect(relationship.active?).to be true
    end

    it 'returns false when end_date is in the past' do
      relationship = create(:relationship, end_date: 1.day.ago)
      expect(relationship.active?).to be false
    end
  end

  describe '#reciprocal_type' do
    it 'returns child for parent' do
      relationship = build(:relationship, relationship_type: 'parent')
      expect(relationship.reciprocal_type).to eq('child')
    end

    it 'returns parent for child' do
      relationship = build(:relationship, relationship_type: 'child')
      expect(relationship.reciprocal_type).to eq('parent')
    end

    it 'returns biological_child for biological_parent' do
      relationship = build(:relationship, relationship_type: 'biological_parent')
      expect(relationship.reciprocal_type).to eq('biological_child')
    end

    it 'returns same type for spouse' do
      relationship = build(:relationship, relationship_type: 'spouse')
      expect(relationship.reciprocal_type).to eq('spouse')
    end

    it 'returns same type for sibling' do
      relationship = build(:relationship, relationship_type: 'sibling')
      expect(relationship.reciprocal_type).to eq('sibling')
    end
  end

  describe 'scopes' do
    let!(:parent_rel) { create(:relationship, relationship_type: 'parent') }
    let!(:child_rel) { create(:relationship, relationship_type: 'child') }
    let!(:spouse_rel) { create(:relationship, relationship_type: 'spouse') }
    let!(:sibling_rel) { create(:relationship, relationship_type: 'sibling') }
    let!(:active_rel) { create(:relationship, end_date: nil) }
    let!(:ended_rel) { create(:relationship, end_date: 1.day.ago) }

    describe '.parents' do
      it 'returns only parent relationships' do
        expect(Relationship.parents).to include(parent_rel)
        expect(Relationship.parents).not_to include(child_rel, spouse_rel, sibling_rel)
      end
    end

    describe '.children' do
      it 'returns only child relationships' do
        expect(Relationship.children).to include(child_rel)
        expect(Relationship.children).not_to include(parent_rel, spouse_rel, sibling_rel)
      end
    end

    describe '.spouses' do
      it 'returns only spousal relationships' do
        expect(Relationship.spouses).to include(spouse_rel)
        expect(Relationship.spouses).not_to include(parent_rel, child_rel, sibling_rel)
      end
    end

    describe '.siblings' do
      it 'returns only sibling relationships' do
        expect(Relationship.siblings).to include(sibling_rel)
        expect(Relationship.siblings).not_to include(parent_rel, child_rel, spouse_rel)
      end
    end

    describe '.active' do
      it 'returns only active relationships' do
        expect(Relationship.active).to include(active_rel)
      end
    end

    describe '.ended' do
      it 'returns only ended relationships' do
        expect(Relationship.ended).to include(ended_rel)
      end
    end
  end
end
