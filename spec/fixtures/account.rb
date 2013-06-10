class Account
  include SoapAdapter::Resource

  def cast_attrs(attrs)
    props = Account.properties
    new_attrs = {}
    attrs.each_pair do |k,v|
      if !v.eql? nil
        case props[k.to_sym].primitive.name
        when 'Integer'
          new_attrs[k.to_sym] = v.to_i
        when 'String'
          new_attrs[k.to_sym] = v.to_str
        else
          new_attrs[k.to_sym] = v
        end
      end
    end
    attrs = new_attrs
  end

  def initialize(attrs = {}, options = {})
    super({})
    attrs = cast_attrs(attrs)
    self.assign_attributes(attrs, as: options[:as] )
  end

  def update_attributes(attrs = {}, options = {})
    attrs = cast_attrs(attrs)
    self.assign_attributes(attrs, as: options[:as] )
    self.save
  end
  
  def assign_attributes(values, options = {})
     values.each do |k, v|
       send("#{k}=", v)
     end
   end
  
  
  def self.default_repository_name
    :default
  end

  property :id,          String, :key => true
  property :name,        String
  property :description, String
  property :fax,         String
  property :phone,       String
  property :type,        String
  property :website,     String
end