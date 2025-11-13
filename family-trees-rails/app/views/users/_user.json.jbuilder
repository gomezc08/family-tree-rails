json.extract! user, :id, :first_name, :last_name, :birthday, :date_died, :gender, :email, :cell, :cityborn, :stateborn, :citycurrent, :statecurrent, :created_at, :updated_at
json.url user_url(user, format: :json)
