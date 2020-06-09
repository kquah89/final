# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"  
require "sinatra/cookies"                                                             #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "bcrypt"
require "geocoder"  
require "twilio-ruby"                                                                    #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

schools_table = DB.from(:schools)
reviews_table = DB.from(:reviews)
users_table = DB.from(:users)


before do
    # SELECT * FROM users WHERE id = session[:user_id]
    @current_user = users_table.where(:id => session[:user_id]).to_a[0]
    puts @current_user.inspect
end

# Home page (all events)
get "/" do
    # before stuff runs
    @schools = schools_table.all
    view "schools"
end

# Show a single event
get "/schools/:id" do
    @users_table = users_table
    # SELECT * FROM events WHERE id=:id
    @school = schools_table.where(:id => params["id"]).to_a[0]
    # SELECT * FROM rsvps WHERE event_id=:id
    @reviews = reviews_table.where(:school_id => params["id"]).to_a
    # SELECT COUNT(*) FROM rsvps WHERE event_id=:id AND going=1
    @count = reviews_table.where(:school_id => params["id"]).count
    #@count = reviews_table.where(:school_id => params["id"], :going => true).count
    # google api
    results = Geocoder.search(@school[:address])
    @lat_long = results.first.coordinates.join(",")
    view "school"
end

# Form to create a new RSVP
get "/schools/:id/reviews/new" do
    @school = schools_table.where(:id => params["id"]).to_a[0]
    view "new_review"
end

# Receiving end of new RSVP form
post "/schools/:id/reviews/create" do
    reviews_table.insert(:school_id => params["id"],
                       :recommend => params["recommend"],
                       :user_id => @current_user[:id],
                       :comments => params["comments"])
    @school = schools_table.where(:id => params["id"]).to_a[0]
    view "create_review"
end

# Form to create a new user
get "/users/new" do
    view "new_user"
end

# Receiving end of new user form
post "/users/create" do
    users_table.insert(:name => params["name"],
                       :mobile => params["mobile"],
                       :email => params["email"],
                       :password => BCrypt::Password.create(params["password"]))
# read your API credentials from environment variables
account_sid = ENV["TWILIO_ACCOUNT_SID"]
auth_token = ENV["TWILIO_AUTH_TOKEN"]

# set up a client to talk to the Twilio REST API
client = Twilio::REST::Client.new(account_sid, auth_token)

# send the SMS from your trial Twilio number to your verified non-Twilio number
client.messages.create(
 from: "+12015848310", 
 to: "+18728882384",
 body: "Thank you for signing up to MBA reviews! Stay tune for updates to the 2021 MBA rankings by following us on our website!"
)
    view "create_user"
end

# Form to login
get "/logins/new" do
    view "new_login"
end

# Receiving end of login form
post "/logins/create" do
    puts params
    email_entered = params["email"]
    password_entered = params["password"]
    # SELECT * FROM users WHERE email = email_entered
    user = users_table.where(:email => email_entered).to_a[0]
    if user
        puts user.inspect
        # test the password against the one in the users table
        if BCrypt::Password.new(user[:password]) == password_entered
            session[:user_id] = user[:id]
            view "create_login"
        else
            view "create_login_failed"
        end
    else 
        view "create_login_failed"
    end
end

# Logout
get "/logout" do
    session[:user_id] = nil
    view "logout"
end