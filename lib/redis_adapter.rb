require 'rubygems'
require 'dm-core'
require 'socket'
require 'redis'

module DataMapper
  module Adapters
    Extlib::Inflection.word 'redis'
    
    class RedisAdapter < AbstractAdapter
      def initialize(name, uri_or_options)
        super
        @redis = Redis.new
        @redis.select_db(@options[:database]) if @options[:database]
      end
      
      def create(resources)
        resources.each do |resource|
          model = resource.model
          
          if identity_field = model.identity_field(name)
            identity_field.set!(resource, @redis.incr("#{resource.model}:serial"))
            @redis.push_tail("#{model}:all", resource.key.to_s)
          end
          
          update_attributes(resource, resource.attributes)
          @redis.push_tail("#{model}:all", resource.key.to_s)
        end
        
        resources.size
      end
      
      def read_one(query)
        read_many(query).first
      end

      def read_many(query)
        model   = query.model
        fields  = query.fields
        
        records_for(model).map do |record|
          model.load(fields.map {|property| property.typecast(@redis["#{model}:#{record}:#{property.name}"]) }, query)
        end
      end
      
      private
      
      def update_attributes(resource, attributes)
        attributes.each do |property, value|
          @redis["#{resource.model}:#{resource.key}:#{property}"] = value
        end
      end
      
      def records_for(model)
        record_ids = @redis.list_range("#{model}:all", 0, -1)
      end
      
    end # class RedisAdapter
    const_added(:RedisAdapter)
  end # module Adapters
end # module DataMapper
