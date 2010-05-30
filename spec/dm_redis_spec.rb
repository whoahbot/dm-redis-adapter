require File.expand_path("../spec_helper", __FILE__)
require 'redis'

# require 'dm-core/spec/adapter_shared_spec'
require DataMapper.root / 'lib' / 'dm-core' / 'spec' / 'shared' / 'adapter_spec'

describe DataMapper::Adapters::RedisAdapter do
  before(:all) do
    @adapter = DataMapper.setup(:default, {
      :adapter  => "redis",
      :db => 15
    })
  end

  it_should_behave_like 'An Adapter'
  
  after(:all) do
    redis = Redis.new(:db => 15)
    redis.flushdb
  end
end
