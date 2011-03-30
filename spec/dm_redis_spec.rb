require 'spec_helper'

require 'dm-core'
require 'dm-core/spec/shared/adapter_spec'
require 'dm-redis-adapter/spec/setup'

ENV['ADAPTER']          = 'redis'
ENV['ADAPTER_SUPPORTS'] = 'all'

describe DataMapper::Adapters::RedisAdapter do
  before(:all) do
    @adapter = DataMapper.setup(:default, {
      :adapter  => "redis",
      :db => 15
    })
    @repository = DataMapper.repository(@adapter.name)
  end

  it_should_behave_like 'An Adapter'

  after(:all) do
    redis = Redis.new(:db => 15)
    redis.flushdb
  end
end
