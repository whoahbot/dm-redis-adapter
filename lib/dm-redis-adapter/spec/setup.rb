require 'dm-redis-adapter'
require 'dm-core/spec/setup'

module DataMapper
  module Spec
    module Adapters

      class RedisAdapter < Adapter
      end

      use RedisAdapter
    end
  end
end
