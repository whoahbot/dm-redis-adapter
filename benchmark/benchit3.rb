require 'benchmark'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/redis_adapter.rb'))

DataMapper.setup(:default, 'postgres://localhost/dm_redis_test')

class Post
  include DataMapper::Resource
  
  property :id,   Serial
  property :text, Text
end

Post.auto_migrate!

Benchmark.benchmark do |x|
  x.report { 1000.times { Post.create(:text => "I like ice cream")}}
end

# Benchmark.benchmark do |x|
#   1000.times { Post.create(:text => "I like ice cream")}
#   x.report { Post.all.each { |p| puts p.text }}
# end