module DataMapper
  module Adapters
    module Soap
      module QueryDelegate
        
        def build_query(query)
          query_hash = {}
          query_hash[:model] = query.model.storage_name(query.repository)          
          query_hash[:fields] = build_queried_fields(query.fields)
          query_hash[:conditions] = build_query_conditions(query.conditions) if query.conditions
          query_hash[:order] = build_query_order(query.order) unless query.order.nil?
          query_hash[:limit] = query.limit unless query.limit.nil?
          query_hash[:offset] = query.offset unless query.offset.nil?
          
          query_hash
        end
        
        def build_queried_fields(properties)
          properties.collect{|property| property.field.to_sym }
        end
        
        def build_query_conditions(conditions)
          conditions.collect do |condition|
            if condition.instance_of? DataMapper::Query::Conditions::EqualToComparison
              {:equal => [condition.subject.field.to_sym, condition.loaded_value]}
            else
              raise "Implement me for #{operand.class}"
            end
          end
        end
        
        def build_query_order(order)
          order.collect do |direction|
            {direction.target.field.to_sym => direction.operator}
          end
        end
      end
    end
  end
end