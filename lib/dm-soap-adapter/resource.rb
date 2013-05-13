class SoapAdapter
  module Resource
    def self.included(model)
      model.send :include, DataMapper::Resource
      model.send :include, SoapAdapter::Property
    end
  end
end