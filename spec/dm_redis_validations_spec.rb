require File.expand_path("../spec_helper", __FILE__)
require 'redis'
require 'dm-validations'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/dm_redis.rb'))

describe DataMapper::Adapters::RedisAdapter do
  before(:all) do
    @adapter = DataMapper.setup(:default, {
      :adapter  => "redis",
      :db => 15
    })

    class Crumblecake
      include DataMapper::Resource
      validates_is_unique :flavor

      property :id,      Serial
      property :flavor,  String, :index => true
    end
  end

  it "should validate unique entries that are indexed" do
    Crumblecake.create(:flavor => "snozzbler")
    Crumblecake.new(:flavor => "snozzbler").valid?.should be_false
  end

  after(:all) do
    redis = Redis.new(:db => 15)
    redis.flush_db
  end
end
