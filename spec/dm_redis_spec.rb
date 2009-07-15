require File.dirname(__FILE__) + '/spec_helper'
require 'redis'

require 'dm-core/spec/adapter_shared_spec'

describe DataMapper::Adapters::RedisAdapter do
  before(:all) do
    @adapter = DataMapper.setup(:default, {
      :adapter  => "redis",
      :db => 15
    })
  end

  after(:all) do
    redis = Redis.new(:db => 15)
    redis.flush_db
  end

  it_should_behave_like 'An Adapter'
end
