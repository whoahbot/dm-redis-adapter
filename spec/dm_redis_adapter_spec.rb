require File.dirname(__FILE__) + '/spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/dm_redis_adapter'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/rubyredis'))

require 'dm-core/spec/adapter_shared_spec'

describe DataMapper::Adapters::RedisAdapter do
  before(:all) do
    @adapter = DataMapper.setup(:default, {
      :adapter  => "redis",
      :db => 15
    })
  end
  
  after(:all) do
    redis = RedisClient.new(:db => 15)
    redis.flushdb
  end
  
  it_should_behave_like 'An Adapter'
end