require 'rubygems'
require 'dm-core'
require 'benchmark'

DataMapper.setup(:default, 'postgres://localhost/dm_redis_test')

class Post
  include DataMapper::Resource

  property :id,   Serial
  property :text, Text
end

Post.auto_migrate!

Benchmark.benchmark do |x|
  x.report { 1000.times { Post.create(:text => "I love coffee") } }
end

Benchmark.benchmark do |x|
  x.report { Post.get(500).text }
end