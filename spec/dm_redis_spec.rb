require File.expand_path("../spec_helper", __FILE__)
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
    redis.flushdb
  end

  it_should_behave_like 'An Adapter'
end
