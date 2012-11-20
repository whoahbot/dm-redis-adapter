require 'spec_helper'

describe DataMapper::Adapters::RedisAdapter do
  before(:all) do
    @adapter = DataMapper.setup(:default, {
        :adapter  => "redis",
        :db => 15
    })

    class Foo_1
            include DataMapper::Resource
            property :hostname,   Text, :key => true
            property :ip_address, Text
    end
    class Foo
          include DataMapper::Resource
          property :key1,   String, :key => true
          property :key2, String, :key => true
        end
          DataMapper.finalize

  end

  after(:each) do
    Redis.new(:db => 15).flushdb
  end

  describe "textual keys" do
    it "should return the key" do


      Foo_1.create(:hostname => "hostname1", :ip_address => '127.0.0.1')

      Foo_1.first.hostname.should == "hostname1"

      Foo_1.first(:hostname => "hostname1").ip_address.should == "127.0.0.1"
    end

    it "should find elements with two natural keys by querying with only one key" do



      Foo.create(:key1 => "value1", :key2 => 'value2')
      Foo.first(:key1 => "value1").key2.should == 'value2'
    end

    it "should support direct key-based query with get using two natural keys" do


      Foo.create(:key1 => "value1", :key2 => 'value2')
      Foo.get("value1","value2").key2.should == 'value2'
    end

  end
end
