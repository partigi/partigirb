require File.dirname(__FILE__) + '/../lib/partigirb'

if ARGV.empty?
  puts "\nUsage: ruby #{__FILE__} user_id_or_login\n\n"
  exit
end

user_id = ARGV.first

def show_reviews(client, reviews, title)
  puts
  puts title 
  puts "-" * title.size
  puts
  
  reviews.each do |review|
      film = client.items.show? :id => review.ptItem_id, :type => 'film'
      puts "- #{film.title}"
      puts "  Comment: #{review.content}"
      puts
  end
  puts
end

client = Partigirb::Client.new

reviews = client.reviews.index? :user_id => user_id, :per_page => 5, :status => 0, :order => 'desc'
show_reviews(client, reviews, "Latest 5 films you want to watch")

reviews = client.reviews.index? :user_id => user_id, :per_page => 5, :status => 1, :order => 'desc'
show_reviews(client, reviews, "Latest 5 films you have seen")

reviews = client.reviews.index? :user_id => user_id, :per_page => 5, :status => 2, :order => 'desc'
show_reviews(client, reviews, "Latest 5 films you own")