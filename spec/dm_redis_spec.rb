require 'spec_helper'

describe DataMapper::Adapters::RedisAdapter do
  before(:all) do
    @adapter = DataMapper.setup(:default, {
      :adapter  => "redis",
      :db => 15
    })
    @repository = DataMapper.repository(@adapter.name)
    @redis = Redis.new(:db => 15)
  end

  it_should_behave_like 'An Adapter'

  describe "adapter level tests" do
    before(:all) do
      class Hooloovoo
        include DataMapper::Resource

        property :id,         Serial
        property :iq,         Integer
        property :shade,      String, :index => true
      end
    end

    it "should save the id of the resource in a set" do
      h = Hooloovoo.create
      @redis.smembers("hooloovoo:id:all").should == [h.id.to_s]
    end

    it "should save indexed fields in a set by Base64 encoding the value" do
      h = Hooloovoo.create(:shade => '336699')
      @redis.smembers("hooloovoo:shade:MzM2Njk5").should == [h.id.to_s]
    end

    it "should create a hash of properties for the resource" do
      h = Hooloovoo.create(:iq => '4069')
      @redis.hmget("hooloovoo:#{h.id}", 'iq').should == ['4069']
    end
  end

  after(:all) do
    @redis.flushdb
  end
end
