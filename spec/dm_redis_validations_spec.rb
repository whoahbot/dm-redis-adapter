require File.dirname(__FILE__) + '/spec_helper'
require 'redis'
require 'dm-validations'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/dm_redis.rb'))

describe DataMapper::Adapters::RedisAdapter do
  before(:all) do
    @adapter = DataMapper.setup(:default, {
      :adapter  => "redis",
      :db => 15
    })
  end
  
  class Post
    include DataMapper::Resource
    validates_is_unique :text

    property :id,     Serial
    property :title,  String, :index => true, :unique => true
  end
  
  it "should validate unique entries that are indexed" do
    Post.create(:title => "tea")
    Post.new(:title => "tea").valid?.should be_false
  end

  after(:all) do
    redis = Redis.new(:db => 15)
    redis.flush_db
  end
end
