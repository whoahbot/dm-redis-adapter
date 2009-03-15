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
          end
          
          resource.attributes.each do |property, value|
            @redis["#{model}:#{resource.key}:#{property}"] = value
          end
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
          model.load(fields.map { |p| record[p.name] }, query)
        end
      end
      
      private
      
      def records_for(model)
        @redis.list_range("#{model}:all", 0, -1)
      end
    end # class RedisAdapter
    const_added(:RedisAdapter)
  end # module Adapters
end # module DataMapper