require 'rubygems'
require 'dm-core'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/dm_redis_adapter.rb'))
require 'redis'
require 'ruby-prof'
require 'benchmark'

DataMapper.setup(:default, {
  :adapter  => "redis",
  :db => 15
})

class Post
  include DataMapper::Resource

  property :id,     Serial
  property :text,   Text
end

class User
  include DataMapper::Resource

  property :id,     Serial
  property :text,   Text
end

1000.times { Post.create(:text => "I like ice cream") }


RubyProf.start
Benchmark.bm(50) do |x|
  x.report("Load the text for 500 posts") { Post.all(:limit => 500).each {|p| p.text} }
end
result = RubyProf.stop

# printer = RubyProf::CallTreePrinter.new(result)
# printer.print(File.open("callgrind.post_get_all.out", 'w'))

r = Redis.new(:db => 15)
r.flush_db