require "rubygems"
require "twitter"
require "csv"
require "redis"
require "pry"

def redis
	rds = Redis.new
end

def twitter
  client = Twitter::REST::Client.new do |config|
    config.consumer_key    = ENV['twitter_consumer_key']
    config.consumer_secret = ENV['twitter_consumer_secret']
  end
end

# second iteration of pulling nested followers
def followers_of_followers
	rds = redis
	client = twitter
	redis_data = rds.lrange 'user_list', 0, 10
	followers_csv = CSV.open("second_nested_followers.csv", "wb") do |csv|
		csv << ["Mizzen Follower ID", "Followers of that ID"]
	cursor = -1
	while (cursor != 0) do
		begin
			redis_data.each do |mizzen_follower|
				mizzen_follower = mizzen_follower.to_i
				csv << [mizzen_follower, "followers in this column"]
				followers = client.followers(mizzen_follower, {:cursor => cursor, :count => 200})
				followers.each do |follower|
					csv << ["", follower.id]
				end
			end
			cursor = followers.next_cursor
			break if cursor == 0
		rescue Twitter::Error::TooManyRequests => error
			sleep error.rate_limit.reset_in
			retry
		else
			raise
			end
		end
	end
end

followers_of_followers()



















# 		def get_followers(username)
# 			# assign twitter method
# 		  client = twitter
# 		  # open csv
# 		  my_csv = CSV.open("#{username}_followers_details.csv", "wb") do |csv|
# 		  	csv << ["#{username} Follower Information"]
# 		  	csv << ["Follower ID", "Follower Name", "Follower Username"]
# 		  # cursor assignment according to twitter docs 
# 		  # https://dev.twitter.com/overview/api/cursoring
# 		  cursor = -1
# 		  while (cursor != 0) do
# 		    begin
# 		    	# assign followers to api result
# 		      followers = client.followers(username, {:cursor => cursor, :count => 200} )
# 		      # loop through each follower assigning their details to csv
# 		      followers.each do |f|
# 		      	csv << [f.id, f.name, f.screen_name]
# 		      end
# 		      # send next cursor to endpoint for more results
# 		      cursor = followers.next_cursor
# 		      # if no more results left
# 		      break if cursor == 0
# 		    rescue Twitter::Error::TooManyRequests => error
# 		        cursor = followers.next_cursor
# 		        sleep error.rate_limit.reset_in
# 		        retry
# 		      else
# 		        raise #exception (i think)
# 		    end
# 		  end
# 		end
# 	end

# get_followers("mizzenandmain")

# borrwed some of this from https://gist.github.com/ronhornbaker/7817176