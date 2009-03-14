require 'benchmark'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/redis_adapter.rb'))

DataMapper.setup(:default, {
  :adapter => 'redis',
  :port => 6379
})

class Post
  include DataMapper::Resource
  
  property :id,   Serial
  property :text, String
end

Benchmark.bmbm do |x|
  x.report { 1000.times { Post.create(:text => "I like ice cream")}}
end