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

  after(:each) do
    @redis.flushdb
  end

  describe "composite keys" do
    before(:all) do
      class CompositeFun
        include DataMapper::Resource

        property :other_id,   Integer, :key => true, :required => true, :index => true
        property :id,         Serial, :key => true
        property :stuff,      String
        
        DataMapper.finalize
      end
    end

    it "should be able to create and update an item with a composite key" do
      c = CompositeFun.new(:other_id => 1)
      c.save
      c.update(:stuff => "Random String")  # Without the fix in adapter#key_query this throws an exception
    end
    
    it "should save the composite id of the resource in a set" do
      c = CompositeFun.new(:other_id => 1)
      c.save
      @redis.hgetall("composite_funs:#{c.other_id}#{c.id}").should == {"other_id" => "#{c.id}"}
      @redis.smembers("composite_funs:other_id:id:all").should == ["#{c.other_id}#{c.id}"]
    end
  end
end
