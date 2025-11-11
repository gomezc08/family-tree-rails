json.extract! person, :id, :first_name, :last_name, :birthday, :date_died, :gender, :email, :cell, :cityborn, :stateborn, :citycurrent, :statecurrent, :created_at, :updated_at
json.url person_url(person, format: :json)
