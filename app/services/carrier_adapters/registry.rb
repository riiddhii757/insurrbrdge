module CarrierAdapters
  class Registry
    class AdapterNotConfigured < StandardError; end

    def self.fetch(carrier)
      case carrier.slug
      when "demo-market"
        DemoAdapter.new
      else
        raise AdapterNotConfigured, "No authorized adapter is configured for #{carrier.name}"
      end
    end
  end
end
