# frozen_string_literal: true

module MyTankInfo
  class InventorySitegroup < Object
    def sites
      @attributes.sites.map { |site| Site.new(site) }
    end
  end
end
