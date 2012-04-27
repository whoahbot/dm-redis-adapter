require 'redis/connection/hiredis'
require 'redis'
require 'base64'

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
        storage_name = resources.first.model.storage_name
        resources.each do |resource|
          initialize_serial(resource, @redis.incr("#{storage_name}:#{redis_key_for(resource.model)}:serial"))
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
        storage_name = query.model.storage_name
        records = records_for(query)
        records.each do |record|
          record_data = @redis.hgetall("#{storage_name}:#{record[redis_key_for(query.model)]}")

          query.fields.each do |property|
            next if query.model.key.include?(property)

            name = property.name.to_s
            value = record_data[name]

            # Integers are stored as Strings in Redis. If there's a
            # string coming out that should be an integer, convert it
            # now. All other typecasting is handled by datamapper
            # separately.
            record[name] = [Integer, Date].include?(property.primitive) ? property.typecast( value ) : value
            record
          end
        end
        query.filter_records(records)
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
        collection.each do |record|
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
        storage_name = resources.first.model.storage_name
        resources.each do |resource|

          model = resource.model
          attributes = resource.dirty_attributes

          resource.model.properties.select {|p| p.index}.each do |property|
            @redis.sadd("#{storage_name}:#{property.name}:#{encode(resource[property.name.to_s])}", resource.key.first.to_s)
          end

          properties_to_set = []
          properties_to_del = []


          fields = model.properties(self.name).select {|property| attributes.key?(property)}
          fields.each do |property|
            value = attributes[property]
            if value.nil?
              properties_to_del << property.name
            else
              properties_to_set << property.name << attributes[property]
            end
          end

          hash_key = "#{storage_name}:#{resource.key.join}"
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

        if query.conditions.nil?
          @redis.smembers(key_set_for(query.model)).each do |key|
            key = key.to_i if key =~ /^\d+$/
            keys << {redis_key_for(query.model) => key}
          end
        else
          query.conditions.operands.each do |operand|
            if operand.is_a?(DataMapper::Query::Conditions::OrOperation)
              operand.each do |op|
                keys = keys + perform_query(query, op)
              end
            else
              keys = perform_query(query, operand)
            end
          end
        end
        keys
      end

      def find_subject_and_value(query, operand)
        if operand.is_a?(DataMapper::Query::Conditions::NotOperation)
          subject = operand.first.subject
          value = operand.first.value
        elsif operand.subject.is_a?(DataMapper::Associations::ManyToOne::Relationship)
          subject = operand.subject.child_key.first
          value = if operand.is_a?(DataMapper::Query::Conditions::InclusionComparison)
            operand.value.map{|v| v[operand.subject.parent_key.first.name]}
          else
            operand.value[operand.subject.parent_key.first.name]
          end
        else
          subject = operand.subject
          value = operand.value
        end

        if subject.is_a?(DataMapper::Associations::ManyToOne::Relationship)
          subject = subject.child_key.first
        end

        return subject, value
      end

      ##
      # Find records that match have a matching value
      #
      # @param [DataMapper::Query] query
      #   The query used to locate the resources to be deleted.
      #
      # @param [DataMapper::Operation] the operation for the query
      #
      # @api private
      def perform_query(query, operand)
        storage_name = query.model.storage_name
        matched_records = []
        subject, value = find_subject_and_value(query, operand)

        case operand
          when DataMapper::Query::Conditions::NotOperation
            if query.model.key.include?(subject)
              @redis.smembers(key_set_for(query.model)).each do |key|
                if operand.matches?(subject.typecast(key))
                  matched_records << {redis_key_for(query.model) => key}
                end
              end
            else
              search_all_resources(query, operand, subject, matched_records)
            end
          when DataMapper::Query::Conditions::InclusionComparison
            if query.model.key.include?(subject)
              value.each do |val|
                if @redis.sismember(key_set_for(query.model), val)
                  matched_records << {redis_key_for(query.model) => val}
                end
              end
            elsif subject.respond_to?(:index) && subject.index
              value.each do |val|
                find_indexed_matches(subject, val).each do |k|
                  matched_records << {redis_key_for(query.model) => k, "#{subject.name}" => val}
                end
              end
            else
              search_all_resources(query, operand, subject, matched_records)
            end
          when DataMapper::Query::Conditions::EqualToComparison
            if query.model.key.include?(subject)
              if @redis.sismember(key_set_for(query.model), value)
                matched_records << {redis_key_for(query.model) => value}
              end
            elsif subject.respond_to?(:index) && subject.index
              find_indexed_matches(subject, value).each do |k|
                matched_records << {redis_key_for(query.model) => k, "#{subject.name}" => value}
              end
            end
          else # worst case here, loop through all members, typecast and match
            search_all_resources(query, operand, subject, matched_records)
          end
        matched_records
      end

      ##
      # Searches through each key :(
      #
      # @api private
      def search_all_resources(query, operand, subject, matched_records)
        @redis.smembers(key_set_for(query.model)).each do |key|
          if operand.matches?(subject.typecast(@redis.hget("#{subject.model.storage_name}:#{key}", subject.name)))
            matched_records << {redis_key_for(query.model) => key}
          end
        end
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
        "#{model.storage_name}:#{redis_key_for(model)}:all"
      end

      ##
      # Find a matching entry for a query
      #
      # @return [Array]
      #   Array of id's of all members for an indexed field
      # @api private
      def find_indexed_matches(subject, value)
        @redis.smembers("#{subject.model.storage_name}:#{subject.name}:#{encode(value)}").map {|id| id.to_i}
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
