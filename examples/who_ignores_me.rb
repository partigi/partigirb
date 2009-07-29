require File.dirname(__FILE__) + '/../lib/partigirb'

if ARGV.empty?
  puts "\nUsage: #{__FILE__} user_id_or_login\n\n"
  exit
end

user_id = ARGV.first

client = Partigirb::Client.new

traitors = []

page = 1
friends = []

# Get logins of people user is following
begin
  friends = client.friendships.index? :user_id => user_id, :type => 'follows', :page => page
  
  friends.each do |friend|
    relationship = client.friendships.show? :source_id => user_id, :target_id => friend.ptUser_id
    traitors << friend.ptUser_login if relationship.ptRelationship_source.ptRelationship_followed_by == 'false'
  end
  
  page += 1
end while !friends.empty?

if traitors.empty?
  "Everything is fine. Everyone you follow is following you."
else
  puts "Those are the ones that don't want to know about you:"
  puts
  traitors.each {|t| puts "  - #{t}"}
end