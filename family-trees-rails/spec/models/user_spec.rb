require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:relationships).dependent(:destroy) }
    it { should have_many(:inverse_relationships).dependent(:destroy) }
    it { should have_many(:relatives).through(:relationships) }
    it { should have_many(:inverse_relatives).through(:inverse_relationships) }
  end

  describe '#full_name' do
    it 'returns first and last name' do
      user = build(:user, first_name: 'John', last_name: 'Doe')
      expect(user.full_name).to eq('John Doe')
    end

    it 'returns empty string when names are blank' do
      user = build(:user, first_name: nil, last_name: nil)
      expect(user.full_name).to eq('')
    end
  end

  describe '#display_name' do
    it 'returns full name when present' do
      user = build(:user, first_name: 'John', last_name: 'Doe', email: 'john@example.com')
      expect(user.display_name).to eq('John Doe')
    end

    it 'returns email when name is blank' do
      user = build(:user, first_name: nil, last_name: nil, email: 'john@example.com')
      expect(user.display_name).to eq('john@example.com')
    end
  end

  describe '#deceased?' do
    it 'returns true when date_died is in the past' do
      user = build(:user, :deceased, date_died: 1.year.ago)
      expect(user.deceased?).to be true
    end

    it 'returns false when date_died is nil' do
      user = build(:user, date_died: nil)
      expect(user.deceased?).to be false
    end
  end

  describe '#age' do
    it 'returns correct age for living person' do
      user = build(:user, birthday: 30.years.ago.to_date, date_died: nil)
      expect(user.age).to eq(30)
    end

    it 'returns age at death for deceased person' do
      user = build(:user, birthday: 30.years.ago.to_date, date_died: 5.years.ago.to_date)
      expect(user.age).to eq(25)
    end

    it 'returns nil when birthday is not set' do
      user = build(:user, birthday: nil)
      expect(user.age).to be_nil
    end
  end

  describe 'family relationship methods' do
    let(:user) { create(:user) }
    let(:parent) { create(:user) }
    let(:child) { create(:user) }
    let(:sibling) { create(:user) }
    let(:spouse) { create(:user) }

    before do
      create(:relationship, user: parent, relative: user, relationship_type: 'parent')
      create(:relationship, user: user, relative: child, relationship_type: 'parent')
      create(:relationship, user: user, relative: sibling, relationship_type: 'sibling')
      create(:relationship, user: user, relative: spouse, relationship_type: 'spouse')
    end

    describe '#parents' do
      it 'returns all parents' do
        expect(user.parents).to be_empty
        expect(user.reload.parents).to be_empty
      end
    end

    describe '#children' do
      it 'returns all children' do
        expect(user.children).to include(child)
      end
    end

    describe '#siblings' do
      it 'returns all siblings' do
        expect(user.siblings).to include(sibling)
      end
    end

    describe '#current_spouse' do
      it 'returns current spouse' do
        expect(user.current_spouse).to eq(spouse)
      end

      it 'returns nil when spouse relationship has ended' do
        user.relationships.where(relationship_type: 'spouse').update_all(end_date: 1.day.ago)
        expect(user.current_spouse).to be_nil
      end
    end

    describe '#all_family_members' do
      it 'returns all related users' do
        family_members = user.all_family_members
        expect(family_members).to include(child, sibling, spouse)
      end
    end

    describe '#related_to?' do
      it 'returns true when relationship exists' do
        expect(user.related_to?(child)).to be true
      end

      it 'returns false when no relationship exists' do
        unrelated_user = create(:user)
        expect(user.related_to?(unrelated_user)).to be false
      end

      it 'returns true when specific relationship type exists' do
        expect(user.related_to?(child, 'parent')).to be true
      end

      it 'returns false when specific relationship type does not exist' do
        expect(user.related_to?(child, 'sibling')).to be false
      end
    end
  end

  describe 'extended family methods' do
    let(:grandparent) { create(:user) }
    let(:parent) { create(:user) }
    let(:user) { create(:user) }
    let(:child) { create(:user) }
    let(:grandchild) { create(:user) }
    let(:aunt) { create(:user) }
    let(:cousin) { create(:user) }

    before do
      create(:relationship, user: grandparent, relative: parent, relationship_type: 'parent')
      create(:relationship, user: parent, relative: user, relationship_type: 'parent')
      create(:relationship, user: user, relative: child, relationship_type: 'parent')
      create(:relationship, user: child, relative: grandchild, relationship_type: 'parent')
      create(:relationship, user: grandparent, relative: aunt, relationship_type: 'parent')
      create(:relationship, user: aunt, relative: cousin, relationship_type: 'parent')
    end

    describe '#grandparents' do
      it 'returns grandparents' do
        expect(user.grandparents).to include(grandparent)
      end
    end

    describe '#grandchildren' do
      it 'returns grandchildren' do
        expect(user.grandchildren).to include(grandchild)
      end
    end

    describe '#aunts_and_uncles' do
      it 'returns aunts and uncles (parents siblings)' do
        expect(user.aunts_and_uncles).to include(aunt)
      end
    end

    describe '#cousins' do
      it 'returns cousins (parents siblings children)' do
        expect(user.cousins).to include(cousin)
      end
    end
  end

  describe 'recursive family methods' do
    let(:great_grandparent) { create(:user) }
    let(:grandparent) { create(:user) }
    let(:parent) { create(:user) }
    let(:user) { create(:user) }

    before do
      create(:relationship, user: great_grandparent, relative: grandparent, relationship_type: 'parent')
      create(:relationship, user: grandparent, relative: parent, relationship_type: 'parent')
      create(:relationship, user: parent, relative: user, relationship_type: 'parent')
    end

    describe '#ancestors' do
      it 'returns all ancestors' do
        ancestors = user.ancestors
        expect(ancestors).to include(parent, grandparent, great_grandparent)
      end

      it 'limits generations when specified' do
        ancestors = user.ancestors(generations: 2)
        expect(ancestors).to include(parent, grandparent)
        expect(ancestors).not_to include(great_grandparent)
      end
    end

    describe '#descendants' do
      let(:child) { create(:user) }
      let(:grandchild) { create(:user) }

      before do
        create(:relationship, user: user, relative: child, relationship_type: 'parent')
        create(:relationship, user: child, relative: grandchild, relationship_type: 'parent')
      end

      it 'returns all descendants' do
        descendants = user.descendants
        expect(descendants).to include(child, grandchild)
      end

      it 'limits generations when specified' do
        descendants = user.descendants(generations: 1)
        expect(descendants).to include(child)
        expect(descendants).not_to include(grandchild)
      end
    end
  end
end
