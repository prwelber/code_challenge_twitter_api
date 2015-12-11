require "rubygems"
require "twitter"
require "pry"
require "csv"
require "redis"

def twitter
  client = Twitter::REST::Client.new do |config|
    config.consumer_key    = ENV['twitter_consumer_key']
    config.consumer_secret = ENV['twitter_consumer_secret']
  end
end
client = twitter

# redis client
rds = Redis.new


### this was the 2nd round attempt, and more closely followed twitter api standards
def get_followers(username)
    # assign twitter method
    client = twitter
    # open csv
    my_csv = CSV.open("#{username}_followers_details.csv", "wb") do |csv|
      csv << ["#{username} Follower Information"]
      csv << ["Follower ID", "Follower Name", "Follower Username"]
    # cursor assignment according to twitter docs 
    # https://dev.twitter.com/overview/api/cursoring
    cursor = -1
    while (cursor != 0) do
      begin
        # assign followers to api result
        followers = client.followers(username, {:cursor => cursor, :count => 200} )
        # loop through each follower assigning their details to csv
        followers.each do |f|
          csv << [f.id, f.name, f.screen_name]
        end
        # also according to docs, send next cursor to endpoint for more results
        cursor = followers.next_cursor
        # if no more results left
        break if cursor == 0
      rescue Twitter::Error::TooManyRequests => error
          cursor = followers.next_cursor
          sleep error.rate_limit.reset_in
          retry
        else
          raise #exception (i think)
      end
    end
  end
end

get_followers("mizzenandmain")

# took some of this from https://gist.github.com/ronhornbaker/7817176

# second iteration of pulling nested followers
# beginning is similar to above
def followers_of_followers
  rds = redis
  client = twitter
  redis_data = rds.lrange 'user_list', 0, 10
  followers_csv = CSV.open("nested_followers.csv", "wb") do |csv|
    csv << ["Mizzen Follower ID", "Followers of that ID"]
  cursor = -1
  while (cursor != 0) do
    begin
      # loop over redis data that contains userIDs of mizzen followers
      redis_data.each do |mizzen_follower|
        mizzen_follower = mizzen_follower.to_i
        # write mizzen follower to csv
        csv << [mizzen_follower, "followers in this column"]
        # api call for followers of the mizzen follower
        followers = client.follower_ids(mizzen_follower, {:cursor => cursor, :count => 200})
        # write nested followers to csv
        followers.each do |follower|
          csv << ["", follower]
        end
      end
      # go to next cursor
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

# these 2nd iterations were the result of viewing this on github
# took some of this from https://gist.github.com/ronhornbaker/7817176


##-----------------------------------------------------------##


### this was the first round attempt at pulling mizzen users - this works
# request to twitter client for mizzen and main list of user ids
follower_ids = client.follower_ids('mizzenandmain')
begin
  follower_ids = f.to_h
rescue Twitter::Error::TooManyRequests => error
  sleep error.rate_limit.reset_in + 1
  retry
end

# store mizzen followers in redis list
follower_ids.each do |data|
  rds.lpush 'user_list', data
end





# open a writable csv file and loop through the followers hash and put each id into the csv file
CSV.open('mizzen_followers.csv', 'wb') do |csv|
  csv << ["Mizzen and Main Followers"]
  followers = rds.lrange 'user_list', 0, -1
  followers.each do |follower|
    csv << [follower]
  end
end



redis_data = rds.lrange 'user_list', 0, 10


# open new writable csv file
CSV.open('followers_of_followers.csv', 'wb') do |csv|
  # write column headers to csv
  csv << ["Mizzen Follower", "Followers of that follower"]
  # iterate over followers hash
  redis_data.each do |follower|
    # write follower id onto csv
    csv << [follower]
    # pull in followers for each each mizzen and main follower and set each follower ID to an integer
    follower = follower.to_i
    f = client.follower_ids(follower.to_i)
    begin
      f = f.to_h
    rescue Twitter::Error::TooManyRequests => error
      sleep error.rate_limit.reset_in + 1
      retry
    end
    # iterate over hash that contains followers of mizzen and main follower
    binding.pry
    f[:ids][0,25].each do |data|
      # put followers into csv file
      csv << ["", data]
    end
  end
end


