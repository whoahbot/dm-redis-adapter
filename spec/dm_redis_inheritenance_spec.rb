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
  describe 'Inheritance' do

    before :all do
      module MINT
      class Person
        include DataMapper::Resource

        property :name, String
        property :job,  String,        :length => 1..255
        property :classtype, Discriminator
        property :id, Serial
      end

      class Male   < Person; end
      class Father < Male;   end
      class Son    < Male;   end

      class Woman    < Person; end
      class Mother   < Woman;  end
      class Daughter < Woman;  end
      end
      DataMapper.finalize

    end

    it 'should select all women, mothers, and daughters based on Woman query' do

       w = MINT::Woman.create(:name => "woman")
      m = MINT::Mother.create(:name => "mother")
      d = MINT::Daughter.create(:name => "daughter")

      r = MINT::Woman.all
      r.to_set.should == [w,m,d].to_set
      r.size.should == [w,m,d].size
    end

    it 'should select all women, mothers, and daughters based on Person query' do
      w = MINT::Woman.create(:name => "woman")
      m = MINT::Mother.create(:name => "mother")
      d = MINT::Daughter.create(:name => "daughter")
      p = MINT::Person.all
      p.to_set.should == [w,m,d].to_set
      p.size.should == [w,m,d].size
    end

    it 'should select all mothers' do
      w = MINT::Woman.create(:name => "woman")
      m = MINT::Mother.create(:name => "mother")
      d = MINT::Daughter.create(:name => "daughter")

      mo = MINT::Mother.all
      mo.to_set.should == [m].to_set
      mo.size.should == [m].size
    end

  end
  after(:each) do
    @redis.flushdb
  end
end
