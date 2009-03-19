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
            @redis.set_add("#{model}:all", resource.key.to_s)
          end
          
          update_attributes(resource, resource.attributes)
        end
        
        resources.size
      end
      
      def read_one(query)
        read_many(query).first
      end

      def read_many(query)
        model   = query.model
        fields  = query.fields
        
        records = records_for(model)
        filter_records(records, query).map! do |record|
          model.load(fields.map {|property| property.typecast(@redis["#{model}:#{record}:#{property.name}"]) }, query)
        end
      end
      
      def update(attributes, query)
        attributes = attributes.map { |p,v| [ p.name, v ] }.to_hash
        
        updated = read_many(query).each do |r|
          update_attributes(r, attributes)
        end
        
        updated.size
      end
      
      def delete(query)
        records = records_for(query.model)
        deleted = filter_records(records, query).map do |record|
          query.model.properties.each do |p|
            @redis.delete("#{query.model}:#{record}:#{p}")
          end
          @redis.set_delete("#{query.model}:all", record)
        end
        deleted.size
      end
      
      private
      
      def update_attributes(resource, attributes)
        attributes.each do |property, value|
          @redis["#{resource.model}:#{resource.key}:#{property}"] = value
        end
      end
      
      def records_for(model)
        @redis.set_members("#{model}:all").to_a
      end
      
      def match_records(records, query)
        conditions = query.conditions

        # Be destructive by using #delete_if
        records.delete_if do |record|
          not conditions.all? do |condition|
            operator, property, bind_value = *condition

            value = property.typecast(@redis["#{query.model}:#{record}:#{property.name}"])

            case operator
              when :eql, :in then equality_comparison(bind_value, value)
              when :not      then !equality_comparison(bind_value, value)
              when :like     then Regexp.new(bind_value) =~ value
              when :gt       then !value.nil? && value >  bind_value
              when :gte      then !value.nil? && value >= bind_value
              when :lt       then !value.nil? && value <  bind_value
              when :lte      then !value.nil? && value <= bind_value
            end
          end
        end

        records
      end
      
      def sort_records(records, query)
        # TODO: sort
        records
      end
    end # class RedisAdapter
    const_added(:RedisAdapter)
  end # module Adapters
end # module DataMapper
