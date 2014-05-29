class SoapAdapter
  module Resource
    def self.included(model)
      model.send :include, DataMapper::Resource
    end
  end
end