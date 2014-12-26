require 'spec_helper'

# FIXME/TODO: Expand these tests to include everything in dm-types

$redis_testing_db_number = 15

describe DataMapper::Adapters::RedisAdapter do
  before(:all) do
    @adapter = DataMapper.setup(:default, {
      :adapter  => "redis",
      :db => $redis_testing_db_number
    })
    @repository = DataMapper.repository(@adapter.name)
    @redis = Redis.new(:db => $redis_testing_db_number)
    @redis.flushdb
  end


  describe "Textual model keys" do
    before(:each) do
      class Person
        include DataMapper::Resource

        property :name,     Text, :key => true
        property :nickname, Text
      end
    end
    before(:each) do
      Redis.new(:db => $redis_testing_db_number).flushdb
      @person = Person.new
    end
    it "Should save and lookup models with textual keys" do
      @person.name = "Humphrey"
      @person.nickname = "hohum"
      @person.save.should be_true

      thing = Person.first(:name => "Humphrey")
      thing.should be_a_kind_of(Person)
      thing.name.should == "Humphrey"
      thing.nickname.should == "hohum"
    end
  end

  describe "Property value reconstitution" do
    before(:each) do
      class Thing
        include DataMapper::Resource

        property :id,                Serial
        property :bool,              Boolean
        property :string,            String
        property :text,              Text
        property :float,             Float
        property :integer,           Integer
        property :datetime,          DateTime
        property :symbolic_enum,     Enum[ :thing_one, :thing_two ]
        property :textual_enum,      Enum[ "thing_one", "thing_two" ]
      end
    end
    before(:each) do
      Redis.new(:db => $redis_testing_db_number).flushdb
      @thing = Thing.new
    end
    
    it "Should save and retrieve Booleans" do
      @thing.bool = true
      @thing.save.should be_true
      id = @thing.id

      thing = Thing.first(:id => id)
      thing.should be_a_kind_of(Thing)
      thing.bool.should be_true
    end
    it "Should save and retrieve Strings" do
      @thing.string = 'foo_bar_baz'
      @thing.save.should be_true
      id = @thing.id

      thing = Thing.first(:id => id)
      thing.should be_a_kind_of(Thing)
      thing.string.should == 'foo_bar_baz'
    end
    it "Should save and retrieve Texts" do
      @thing.text = 'foo_bar_baz'
      @thing.save.should be_true
      id = @thing.id

      thing = Thing.first(:id => id)
      thing.should be_a_kind_of(Thing)
      thing.text.should == 'foo_bar_baz'
    end
    it "Should save and retrieve Floats" do
      @thing.float = 3.14159
      @thing.save.should be_true
      id = @thing.id

      thing = Thing.first(:id => id)
      thing.should be_a_kind_of(Thing)
      thing.float.should == 3.14159
    end
    it "Should save and retrieve Integers" do
      @thing.integer = 42
      @thing.save.should be_true
      id = @thing.id

      thing = Thing.first(:id => id)
      thing.should be_a_kind_of(Thing)
      thing.integer.should == 42
    end
    it "Should save and retrieve DateTime" do
      now = DateTime.now
      @thing.datetime = now
      @thing.save.should be_true
      id = @thing.id

      thing = Thing.first(:id => id)
      thing.should be_a_kind_of(Thing)
      thing.datetime.should == now
    end
    it "Should save and retrieve textual Enums" do
      @thing.textual_enum = "thing_one"
      @thing.save.should be_true
      id = @thing.id

      thing = Thing.first(:id => id)
      thing.should be_a_kind_of(Thing)
      thing.textual_enum.should == "thing_one"
    end
    it "Should save and retrieve symbolic Enums" do
      @thing.symbolic_enum = :thing_one
      @thing.save.should be_true
      id = @thing.id

      thing = Thing.first(:id => id)
      thing.should be_a_kind_of(Thing)
      thing.symbolic_enum.should == :thing_one
    end
  end
end
