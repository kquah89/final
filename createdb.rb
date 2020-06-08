# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :schools do
  primary_key :id
  String :title
  String :description, text: true
  String :date
  String :location
end
DB.create_table! :reviews do
  primary_key :id
  foreign_key :school_id
  foreign_key :user_id
  Boolean :going
  String :comments, text: true
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
end

# Insert initial (seed) data
schools_table = DB.from(:schools)

schools_table.insert(title: "University of Chicago (Booth)", 
                    description: "The University of Chicago Booth School of Business (also known as Chicago Booth, or Booth) is the graduate business school of the University of Chicago in Chicago, Illinois. The University of Chicago, including Booth faculty, has produced more Nobel laureates in the Economic Sciences than any other school. Formerly known as The University of Chicago Graduate School of Business, Chicago Booth is the second-oldest business school in the U.S. The Full-Time MBA Program is currently tied for third with Harvard Business School and the MIT Sloan School of Management according to U.S. News & World Report.",
                    # date: "June 21",
                    location: "Chicago, Illinois, United States")

schools_table.insert(title: "Northwestern University (Kellogg)", 
                    description: "The Kellogg School of Management at Northwestern University (also known as Kellogg) is the business school of Northwestern University, located in the Chicago Metropolitan Area, Illinois. Founded in 1908, Kellogg pioneered the use of group projects and evaluations and popularized the importance of team leadership within the business world. Kellogg's 2-Yr MBA Program is currently ranked #3 in the U.S. according to U.S. News & World Report and Forbes Magazine and #4 globally according to The Economist.",
                    #date: "July 4",
                    location: "Evanston, Illinois, United States")