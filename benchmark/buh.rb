require 'rubygems'
require 'dm-core'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/dm_redis_adapter.rb'))
require 'ruby-prof'

DataMapper.setup(:default, {
  :adapter  => "redis",
  :database => 15,
  :debug => true
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

# 1000.times { Post.create(:text => "I like ice cream") }

# RubyProf.start
#Benchmark.benchmark do |x|
#  x.report { Post.get(500) }
#end
# result = RubyProf.stop

p = Post.get(500)
p.text = "Jabba"
p.save

p = Post.get(500)
puts p.text

# Post.get(p.id).destroy

# printer = RubyProf::CallTreePrinter.new(result)
# printer.print(File.open("callgrind.out.post_get.new", 'w'))

# r = Redis.new(:db => 15)
# r.flush_db