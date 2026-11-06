module CarrierAdapters
  class Registry
    class AdapterNotConfigured < StandardError; end

    def self.fetch(carrier)
      return DemoAdapter.new if carrier.environment == "demo"

      raise AdapterNotConfigured, "No authorized adapter is configured for #{carrier.name}"
    end
  end
end
