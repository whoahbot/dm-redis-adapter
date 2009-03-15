require File.dirname(__FILE__) + '/spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib/redis_adapter.rb'))

describe DataMapper::Adapters::RedisAdapter do
  before(:all) do
    @adapter = DataMapper.setup(:default, {
      :adapter  => "redis",
      :database => 15
    })
    @repository = DataMapper.repository(@adapter.name)
    
    class Post
      include DataMapper::Resource
      
      property :id,   Serial
      property :text, Text
    end
    
    @model    = Post
    @resource = @model.new(:text => "I'm a stupid blog!")
  end
  
  after(:all) do
    # Ghetto delete all
    r = Redis.new
    r.keys('*').each {|k| r.delete k }
  end
  
  it { @adapter.should respond_to(:create) }
  
  describe "#create" do
    before(:all) do
      @return = @adapter.create([@resource])
    end
    
    it 'should return the number of records created' do
      @return.should == 1
    end
    
    it "should set an id for it's serial field when saved" do
      @resource.id.should_not be_nil
    end
    
    it "should set the serial field on each create" do
      @model.create(:text => "Hey, I'm a cretin!").id.should_not be_nil
    end
  end
  
  it { @adapter.should respond_to(:read_many) }
  
  describe "#read_many" do
    before(:each) do
      @resource.save
      @return = @adapter.read_many(DataMapper::Query.new(@repository, @model, :id => @resource.id))
    end
    
    it 'should return an Array' do
      @return.should be_a_kind_of(Array)
    end
    
    it "should return all records" do
      @return.should include(@resource)
    end
  end
end