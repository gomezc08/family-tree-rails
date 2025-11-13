FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.unique.email }
    password { "password123" }
    password_confirmation { "password123" }
    birthday { Faker::Date.birthday(min_age: 18, max_age: 90) }
    gender { %w[male female].sample }
    citycurrent { Faker::Address.city }
    statecurrent { Faker::Address.state_abbr }
    cityborn { Faker::Address.city }
    stateborn { Faker::Address.state_abbr }

    trait :deceased do
      date_died { Faker::Date.between(from: 1.year.ago, to: Date.today) }
    end

    trait :with_full_profile do
      cell { Faker::PhoneNumber.cell_phone }
    end
  end
end
