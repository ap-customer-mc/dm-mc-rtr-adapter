#!/usr/bin/ruby
#
# More of a straight-up example of a script using salesforce-adapter.
# Use script/console to interact with the spec fixtures via IRB.
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
xtra = File.expand_path('../api', __FILE__)
$LOAD_PATH.unshift(xtra) unless $LOAD_PATH.include?(xtra)

require 'rubygems'
require 'dm-core'
require 'dm-soap-adapter'

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
    :soap
  end

  property :id,          String, :key => true
  property :name,        String
  property :description, String
  property :fax,         String
  property :phone,       String
  property :type,        String
  property :website,     String
end

class Contact
  include SoapAdapter::Resource

  def self.default_repository_name
    :soap
  end

  property :id,         Serial
  property :first_name, String
  property :last_name,  String
  property :email,      String

  belongs_to :account
end


@adapter = DataMapper.setup(:soap, {:adapter  => 'soap',
                               :path     => "http://localhost:3000/accounts/wsdl",
                               :class    => Account,
                               :methods => {:create => 'createAccount',
                                            :read => 'getAccount',
                                            :update => 'updateAccount',
                                            :delete => 'deleteAccount',
                                            :all => 'allAccounts'}})
                               
                               
                               
first = Account.new(  :id => '10004',
                      :name => 'name',
                      :description => 'description', 
                      :fax => 'fax',
                      :phone => 'phone', 
                      :type => 'type',
                      :website => 'website')

second = Account.new( :id => '10004',
                      :name => 'name_updated',
                      :description => 'description_updated', 
                      :fax => 'fax_updated',
                      :phone => 'phone_updated', 
                      :type => 'type_updated',
                      :website => 'website_updated')

puts 'testing create...'
first = Account.create(first.attributes)
puts 'testing update...'
puts @adapter.update(second, first)
puts 'testing read'
Account.get(10004)
puts 'testing delete...'
puts @adapter.delete(1005)
puts 'testing all...'
puts @adapter.all()

 



