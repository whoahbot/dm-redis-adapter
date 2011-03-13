require 'redis'
require "base64"

module DataMapper
  module Adapters
    class RedisAdapter < AbstractAdapter
      ##
      # Used by DataMapper to put records into the redis data-store: "INSERT" in SQL-speak.
      # It takes an array of the resources (model instances) to be saved. Resources
      # each have a key that can be used to quickly look them up later without
      # searching.
      #
      # @param [Enumerable(Resource)] resources
      #   The set of resources (model instances)
      #
      # @api semipublic
      def create(resources)
        resources.each do |resource|
          initialize_serial(resource, @redis.incr("#{resource.model.to_s.downcase}:#{redis_key_for(resource.model)}:serial"))
          @redis.sadd(key_set_for(resource.model), resource.key.join)
        end
        update_attributes(resources)
      end

      ##
      # Looks up one record or a collection of records from the data-store:
      # "SELECT" in SQL.
      #
      # @param [Query] query
      #   The query to be used to seach for the resources
      #
      # @return [Array]
      #   An Array of Hashes containing the key-value pairs for
      #   each record
      #
      # @api semipublic
      def read(query)
        records = records_for(query).each do |record|
          record_data = @redis.hgetall("#{query.model.to_s.downcase}:#{record[redis_key_for(query.model)]}")

          query.fields.each do |property|
            next if query.model.key.include?(property)

            name = property.name.to_s
            value = record_data[name]

            # Integers are stored as Strings in Redis. If there's a
            # string coming out that should be an integer, convert it
            # now. All other typecasting is handled by datamapper
            # separately.
            record[name] = [Integer, Date].include?(property.primitive) ? property.typecast( value ) : value
          end
        end
        records = query.match_records(records)
        records = query.sort_records(records)
        records
      end

      ##
      # Used by DataMapper to update the attributes on existing records in the redis
      # data-store: "UPDATE" in SQL-speak. It takes a hash of the attributes
      # to update with, as well as a collection object that specifies which resources
      # should be updated.
      #
      # @param [Hash] attributes
      #   A set of key-value pairs of the attributes to update the resources with.
      # @param [DataMapper::Collection] collection
      #   The collection object that should be used to find the resource(s) to update.
      #
      # @api semipublic
      def update(attributes, collection)
        attributes = attributes_as_fields(attributes)

        records_to_update = records_for(collection.query)
        records_to_update.each {|r| r.update(attributes)}
        update_attributes(collection)
      end

      ##
      # Destroys all the records matching the given query. "DELETE" in SQL.
      #
      # @param [DataMapper::Collection] collection
      #   The query used to locate the resources to be deleted.
      #
      # @return [Array]
      #   An Array of Hashes containing the key-value pairs for
      #   each record
      #
      # @api semipublic
      def delete(collection)
        collection.count.times do |x|
          record = collection[x]
          @redis.del("#{collection.query.model.to_s.downcase}:#{record[redis_key_for(collection.query.model)]}")
          @redis.srem(key_set_for(collection.query.model), record[redis_key_for(collection.query.model)])
          record.model.properties.select {|p| p.index}.each do |p|
            @redis.srem("#{collection.query.model.to_s.downcase}:#{p.name}:#{encode(record[p.name])}", record[redis_key_for(collection.query.model)])
          end
        end
      end

      private

      ##
      # Saves each resource to the redis data store
      #
      # @param [Array] Resources
      #   An array of resource to save
      #
      # @api private
      def update_attributes(resources)
        resources.each do |resource|
          model = resource.model
          attributes = resource.dirty_attributes

          resource.model.properties.select {|p| p.index}.each do |property|
            @redis.sadd("#{resource.model.to_s.downcase}:#{property.name}:#{encode(resource[property.name.to_s])}", resource.key.first.to_s)
          end

          properties_to_set = []
          properties_to_del = []

          fields = model.properties(self.name).select {|property| attributes.key?(property) }
          fields.each do |property|
            value = attributes[property]
            if value.nil?
              properties_to_del << property.name
            else
              properties_to_set << property.name << attributes[property]
            end
          end

          hash_key = "#{resource.model.to_s.downcase}:#{resource.key.join}"
          properties_to_del.each {|prop| @redis.hdel(hash_key, prop) }
          @redis.hmset(hash_key, *properties_to_set) unless properties_to_set.empty?
        end
      end

      ##
      # Retrieves records for a particular model.
      #
      # @param [DataMapper::Query] query
      #   The query used to locate the resources
      #
      # @return [Array]
      #   An array of hashes of all of the records for a particular model
      #
      # @api private
      def records_for(query)
        keys = []

        query.conditions.operands.select {|o| o.is_a?(DataMapper::Query::Conditions::EqualToComparison)}.each do |o|
          if query.model.key.include?(o.subject)
            if @redis.sismember(key_set_for(query.model), o.value)
              keys << {"#{redis_key_for(query.model)}" => o.value}
            end
          end
          find_matches(query, o).each do |k|
            keys << {"#{redis_key_for(query.model)}" => k.to_i, "#{o.subject.name}" => o.value}
          end
        end

        if keys.empty? && (query.order || query.limit)
          params = {}
          params[:limit] = [query.offset, query.limit] if query.limit

          if query.order
            order = query.order.first
            params[:order] = order.operator.to_s
          end

          @redis.sort(key_set_for(query.model), params).each do |val|
            keys << {"#{redis_key_for(query.model)}" => val.to_i}
          end
        end

        # Keys are empty, fall back and load all the values for this model
        if keys.empty?
          @redis.smembers(key_set_for(query.model)).each do |val|
            keys << {"#{redis_key_for(query.model)}" => val.to_i}
          end
        end

        keys
      end

      ##
      # Creates a string representation for the keys in a given model
      #
      # @param [DataMapper::Model] model
      #   The query used to locate the resources to be deleted.
      #
      # @return [String]
      #   A string representation of the string key for this model
      #
      # @api private
      def redis_key_for(model)
        model.key.collect {|k| k.name}.join(":")
      end

      ##
      # Return the key string for the set that contains all keys for a particular resource
      #
      # @return String
      #   The string key for the :all set
      # @api private
      def key_set_for(model)
        "#{model.to_s.downcase}:#{redis_key_for(model)}:all"
      end

      ##
      # Find a matching entry for a query
      #
      # @return [Array]
      #   Array of id's of all members matching the query
      # @api private
      def find_matches(query, operand)
        @redis.smembers("#{query.model.to_s.downcase}:#{operand.subject.name}:#{encode(operand.value)}")
      end

      ##
      # Base64 encode a value as a string key for an index
      #
      # @return String
      #   Base64 representation of a value
      # @api private
      def encode(value)
        Base64.encode64(value.to_s).gsub("\n", "")
      end

      ##
      # Make a new instance of the adapter. The @redis ivar is the 'data-store'
      # for this adapter.
      #
      # @param [String, Symbol] name
      #   The name of the Repository using this adapter.
      # @param [String, Hash] uri_or_options
      #   The connection uri string, or a hash of options to set up
      #   the adapter
      #
      # @api semipublic
      def initialize(name, uri_or_options)
        super
        @redis = Redis.new(@options)
      end
    end # class RedisAdapter

    const_added(:RedisAdapter)
  end # module Adapters
end # module DataMapper
