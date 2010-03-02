require 'rubygems'
require 'dm-core'
require 'benchmark'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/dm_redis.rb'))

class Post
  include DataMapper::Resource
  
  property :id,     Serial
  property :text,   String
  property :points, Integer
end

redis = Redis.new(:db => 15)

# DataMapper.setup(:default, {:adapter  => "redis", :db => 15 })
# DataMapper.setup(:default, 'postgres://localhost/dm_redis_test')

Benchmark.bm(50) do |x|
  DataMapper.setup(:default, {:adapter  => "redis", :db => 15 })
  x.report("Create 1000 posts with DM and Redis") { 1000.times { Post.create(:text => "I love coffee") } }

  DataMapper.setup(:default, 'postgres://localhost/dm_redis_test')
  Post.auto_migrate!
  x.report("Create 1000 posts with DM and Postgres") { 1000.times { Post.create(:text => "I love coffee") } }

  x.report("Create 1000 posts with Redis") do 
    1000.times do
      i = redis.incr("Post:serial")
      redis.set_add("Post:id:all", i)
      redis["Post:#{i}:text"] = "I love coffee"
    end
  end
end

Benchmark.bm(50) do |x|
  DataMapper.setup(:default, {:adapter  => "redis", :db => 15 })
  x.report("Fetch the 500th post with DM and Redis") { Post.get(500).text }
  DataMapper.setup(:default, 'postgres://localhost/dm_redis_test')
  x.report("Fetch the 500th post's text with DM and Postgres") { Post.get(500).text }
  x.report("Fetch the 500th post's text with Redis") { redis.set_member?("Post:id:all", 500); redis["Post:500:text"] }
end

Benchmark.bm(50) do |x|
  DataMapper.setup(:default, {:adapter  => "redis", :db => 15 })
  x.report("Fetch the 500th post's text with DM and Redis") { Post.get(500).text }
  DataMapper.setup(:default, 'postgres://localhost/dm_redis_test')
  x.report("Fetch the 500th post's text with DM and Postgres") { Post.get(500).text }
  x.report("Fetch the 500th post's text with Redis") { redis.set_member?("Post:id:all", 500); redis["Post:500:text"] }
end

Benchmark.bm(50) do |x|
  DataMapper.setup(:default, {:adapter  => "redis", :db => 15 })
  x.report("Fetch the text of all posts with DM and Redis") { Post.all.each {|p| p.text} }
  DataMapper.setup(:default, 'postgres://localhost/dm_redis_test')
  x.report("Fetch the text of all posts with DM and Postgres") { Post.all.each {|p| p.text} }
  x.report("Fetch the text of all posts with Redis") { 1000.times {|n| redis["Post:#{n}:text"]} }
end

redis.flushdb
