module VCAP::CloudController::RoutingApi
  class RouterGroup
    attr_reader :guid, :types
    def initialize(hash)
      @guid = hash['guid']
      @types = hash['types']
    end

    def ==(other)
      guid == other.guid
    end
  end
end
