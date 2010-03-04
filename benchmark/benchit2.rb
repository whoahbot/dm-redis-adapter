require 'benchmark'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/dm_redis_adapter.rb'))

DataMapper.setup(:default, 'sqlite3::memory:')

class Post
  include DataMapper::Resource

  property :id,   Serial
  property :text, Text
end

Post.auto_migrate!

Benchmark.benchmark do |x|
  x.report { 1000.times { Post.create(:text => "I like ice cream")}}
end