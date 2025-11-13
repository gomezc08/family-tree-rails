FactoryBot.define do
  factory :relationship do
    association :user
    association :relative, factory: :user
    relationship_type { "parent" }
    start_date { Faker::Date.between(from: 30.years.ago, to: Date.today) }

    trait :parent_child do
      relationship_type { "parent" }
    end

    trait :biological_parent_child do
      relationship_type { "biological_parent" }
    end

    trait :spousal do
      relationship_type { "spouse" }
    end

    trait :sibling do
      relationship_type { "sibling" }
    end

    trait :ended do
      end_date { Faker::Date.between(from: 1.year.ago, to: Date.today) }
    end

    trait :with_notes do
      notes { Faker::Lorem.paragraph }
    end
  end
end
