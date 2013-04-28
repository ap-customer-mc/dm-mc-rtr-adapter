class SOAPAdapter
  module Resource
    def self.included(model)
      model.send :include, DataMapper::Resource
      model.send :include, SOAPAdapter::Property
    end
  end
end