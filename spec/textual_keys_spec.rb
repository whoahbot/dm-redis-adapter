require 'spec_helper'

describe DataMapper::Adapters::RedisAdapter do
  before(:all) do
    @adapter = DataMapper.setup(:default, {
      :adapter  => "redis",
      :db => 15
    })
  end

  after(:all) do
    Redis.new(:db => 15).flushdb
  end

  describe "textual keys" do
    it "should return the key" do
      class Foo
        include DataMapper::Resource
        property :hostname,   Text, :key => true
        property :ip_address, Text
      end
      DataMapper.finalize

      Foo.create(:hostname => "hostname1", :ip_address => '127.0.0.1')

      Foo.first.hostname.should == "hostname1"
    end
  end
end
