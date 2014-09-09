login = "user@example.com"
pass = "changeme"
User.create(email: login, password: pass)
puts "User #{login}:#{pass} has been created successfully"