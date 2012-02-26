require 'multi_bit_field/core_ext'

module MultiBitField  
  module ClassMethods
    # MultiBitField creates convenience methods for using
    # multiple filum bit-fields with ActiveRecord.
    # Author:: Aaron Spiegel
    # Copyright:: Copyright (c) 2012 Aaron Spiegel
    # License:: MIT License (http://www.opensource.org/licenses/mit-license.php)
    #
    # Assign bitfields to a column
    #
    # +has_bit_field :column, :fields
    #
    # @example
    #   class User < ActiveRecord::Base
    #     has_bit_field :counter, :daily => 0..4, :weekly => 5..9, :monthly => 10..14
    #   end
    #
    # @param [ Symbol ] counter Integer attribute to store bitfields
    # @param [ Hash ]   fields  Specify the bitfield name, and the columns
    #                           of the bitstring assigned to it
    def has_bit_field column, fields
      set_bitfields! column, fields
      
      fields.each do |field_name, filum|
        class_eval <<-EVAL
          def #{field_name}
            get_bits_for(:#{column}, #{filum})
          end

          def #{field_name}=(value)
            set_bits_for(:#{column}, #{filum}, value)
          end
        EVAL
      end
    end

    def bitfields
      @@bitfields
    end
    
    private
    
    def set_bitfields! column, fields
      if defined?(@@bitfields)
        # set the 
        @@bitfields[column] = fields.values.sum.count
      else
        @@bitfields = { column => fields.values.sum.count }
      end
    end
  end  
  
  module InstanceMethods
    private
    
    # self[column_name].to_s(2)                -- converts integer to binary string
    # self[column_name].to_s(2)[filum]         -- selects range or integer from string
    # self[column_name].to_s(2)[filum].to_i(2) -- converts it back to an integer
    def get_bits_for(column, filum)
      return nil if self[column].nil?
      length     = self.class.bitfields[column]
      bit_string = self[column].to_i.to_s(2)
      
      sprintf("%0#{length}d", bit_string)[filum].to_i(2)
    end

    def set_bits_for(column, filum, value)
      length     = self.class.bitfields[column]
      bit_string = self[column].to_i.to_s(2)
      temp_field = sprintf("%0#{length}d", bit_string)

      raise ArgumentError, "Attempted value: #{value} is too large for selected filum" \
        if filum.count < value.to_i.to_s(2).length

      # replace filum section
      temp_field[filum] = sprintf("%0#{filum.count}d", value.to_i.to_s(2))
      
      # replace with integer value
      self[column] = temp_field.to_i(2)
    end
    
  end
  
  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end