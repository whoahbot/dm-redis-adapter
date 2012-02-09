require 'spec_helper'

describe DataMapper::Adapters::RedisAdapter do
  before(:all) do
    @adapter = DataMapper.setup(:default, {
      :adapter  => "redis",
      :db => 15
    })
    @repository = DataMapper.repository(@adapter.name)
    @redis = Redis.new(:db => 15)
    @redis.flushdb
  end

  describe "Type coercision" do
    before(:all) do
      class Person
        include DataMapper::Resource

        property :name,     Text, :key => true
        property :nickname, Text
      end
      class Thing
        include DataMapper::Resource

        property :id,     Serial
        property :number, Integer
        property :bool,   Boolean
        property :enum,   Enum[ :thing_one, :thing_two ]
        property :float,  Float
      end
    end

    it "Should save and lookup models with textual keys" do
      thing = Person.new
      thing.name = "Jonathan"
      thing.nickname = "jof"
      thing.save.should be_true

      thing = Person.first(:name => "Jonathan")
      thing.should be_a_kind_of(Person)
      thing.name.should == "Jonathan"
      thing.nickname.should == "jof"
    end
    it "Should save and retrieve Integers" do
      thing = Thing.new
      thing.number = 42
      thing.save.should be_true
      id = thing.id

      thing = Thing.first(:id => id)
      thing.should be_a_kind_of(Thing)
      thing.number.should == 42
    end
    it "Should save and retrieve Booleans" do
      thing = Thing.new
      thing.bool = true
      thing.save.should be_true
      id = thing.id

      thing = Thing.first(:id => id)
      thing.should be_a_kind_of(Thing)
      thing.bool.should be_true
    end
    it "Should save and retrieve Floats" do
      thing = Thing.new
      thing.float = 3.14159
      thing.save.should be_true
      id = thing.id

      thing = Thing.first(:id => id)
      thing.should be_a_kind_of(Thing)
      thing.float.should == 3.14159
    end
    it "Should save and retrieve Enums" do
      thing = Thing.new
      thing.enum = :thing_one
      thing.save.should be_true
      id = thing.id

      thing = Thing.first(:id => id)
      thing.should be_a_kind_of(Thing)
      thing.enum.should == :thing_one
    end
  end
end
