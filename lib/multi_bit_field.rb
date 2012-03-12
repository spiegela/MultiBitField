# MultiBitField creates convenience methods for using
# multiple filum bit-fields with ActiveRecord.
# Author:: Aaron Spiegel
# Copyright:: Copyright (c) 2012 Aaron Spiegel
# License:: MIT License (http://www.opensource.org/licenses/mit-license.php)
require 'multi_bit_field/core_ext'

module MultiBitField  
  module ClassMethods
    # alias :reset_bitfields :reset_bitfield
    
    # Assign bitfields to a column
    #
    # +has_bit_field :column, :fields
    #
    # @example
    #   class User < ActiveRecord::Base
    #     has_bit_field :counter, :daily => 0..4, :weekly => 5..9, :monthly => 10..14
    #   end
    #
    # @param [ Symbol ] column  Integer attribute to store bitfields
    # @param [ Hash ]   fields  Specify the bitfield name, and the columns
    #                           of the bitstring assigned to it
    def has_bit_field column, fields
      bitfield_setup! column, fields
      
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
    
    # Returns the size of the bitfield in number of bits
    #
    # +bitfield_size :column
    #
    # @example
    #  user.bitfield_size :counter
    #
    # @param [ Symbol ] column_name  column name that stores the bitfield integer
    #
    def bitfield_size column_name
      @@bitfields[column_name].values.sum.count
    end
    
    # Returns the field names for the bitfield column
    #
    # +bitfields
    #
    # @example
    #  user.bitfields :counter
    #
    # @param [ Symbol ] column_name column name that stores the bitfield integer
    #
    def bitfields column_name
      @@bitfields[column_name].keys
    end
    
    # Returns a "reset mask" for a list of fields
    #
    # +reset_mask_for :fields
    #
    # @example
    #  user.reset_mask_for :field
    #
    # @param [ Symbol ] column     name of the column these fields are in
    # @param [ Symbol ] field(s) name of the field(s) for the mask
    def reset_mask_for column_name, *fields
      fields = bitfields if fields.empty?
      fields.inject("1" * bitfield_size(column_name)) do |mask, field_name|
        column = @@bitfields[column_name]
        raise ArgumentError, "Unknown column for bitfield: #{column_name}" if column.nil?
        raise ArugmentError, "Unknown field: #{field_name} for column #{column_name}" if column[field_name].nil?
        range = column[field_name]
        mask[range] = "0" * range.count
        mask
      end.to_i(2)
    end
    
    # Returns an "increment mask" for a list of fields
    #
    # +increment_mask_for :fields
    #
    # @example
    #  user.increment_mask_for :field
    #
    # @param [ Symbol ] column     name of the column these fields are in
    # @param [ Symbol ] field(s) name of the field(s) for the mask
    def increment_mask_for column_name, *fields
      fields = bitfields if fields.empty?
      fields.inject("0" * bitfield_size(column_name)) do |mask, field_name|
        column = @@bitfields[column_name]
        raise ArgumentError, "Unknown column for bitfield: #{column_name}" if column.nil?
        raise ArugmentError, "Unknown field: #{field_name} for column #{column_name}" if column[field_name].nil?
        range = column[field_name]
        mask[range.last] = "1"
        mask
      end.to_i(2)
    end
    
    # Returns an "only mask" for a list of fields
    #
    # +only_mask_for :fields
    #
    # @example
    #  user.only_mask_for :field
    #
    # @param [ Symbol ] column     name of the column these fields are in
    # @param [ Symbol ] field(s) name of the field(s) for the mask
    def only_mask_for column_name, *fields
      fields = bitfields if fields.empty?
      fields.inject("0" * bitfield_size(column_name)) do |mask, field_name|
        column = @@bitfields[column_name]
        raise ArgumentError, "Unknown column for bitfield: #{column_name}" if column.nil?
        raise ArugmentError, "Unknown field: #{field_name} for column #{column_name}" if column[field_name].nil?
        range = column[field_name]
        mask[range] = "1" * range.count
        mask
      end.to_i(2)
    end
    
    # Sets one or more bitfields to 0 within a column
    #
    # +reset_bitfield :column, :fields
    #
    # @example
    #   User.reset_bitfield :column, :daily, :monthly
    #
    # @param [ Symbol ] column     name of the column these fields are in
    # @param [ Symbol ] field(s)   name of the field(s) to reset
    def reset_bitfields column_name, *fields
      mask = reset_mask_for column_name, *fields
      update_all "#{column_name} = #{column_name} & #{mask}"
    end
    alias :reset_bitfield :reset_bitfields
        
    # Increases one or more bitfields by 1 value
    #
    # +increment_bitfield :column, :fields
    #
    # @example
    #   user.increment_bitfield :column, :daily, :monthly
    #
    # @param [ Symbol ] column     name of the column these fields are in
    # @param [ Symbol ] field(s)   name of the field(s) to reset
    def increment_bitfields column_name, *fields
      mask = increment_mask_for column_name, *fields
      update_all "#{column_name} = #{column_name} + #{mask}"
    end
    alias :increment_bitfield :increment_bitfields

    # Counts resources grouped by a bitfield
    #
    # +count_by :column, :fields
    #
    # @example
    #   user.count_by :counter, :monthly
    #
    # @param [ Symbol ] column     name of the column these fields are in
    # @param [ Symbol ] field(s)   name of the field(s) to reset
    def count_by column_name, field
      inc = increment_mask_for column_name, field
      only = only_mask_for column_name, field
      # Create super-special-bitfield-grouping-query w/ AREL
      sql = arel_table.
        project("count(#{primary_key}) as #{field}_count, (#{column_name} & #{only})/#{inc} as #{field}").
        group(field).to_sql
      connection.send :select, sql, 'AREL' # Execute the query
    end

    private
    
    def bitfield_setup! column, fields
      if defined?(@@bitfields)
        @@bitfields[column] = fields
      else
        @@bitfields = { column => fields }
      end
    end    
  end  
  
  module InstanceMethods
    # Sets one or more bitfields to 0 within a column
    #
    # +reset_bitfield :column, :fields
    #
    # @example
    #   user.reset_bitfield :column, :daily, :monthly
    #
    # @param [ Symbol ] column     name of the column these fields are in
    # @param [ Symbol ] field(s)   name of the field(s) to reset
    def reset_bitfields column_name, *fields
      mask = self.class.reset_mask_for column_name, *fields
      self[column_name] = self[column_name] & mask
      save
    end
    alias :reset_bitfield :reset_bitfields
    
    # Increases one or more bitfields by 1 value
    #
    # +increment_bitfield :column, :fields
    #
    # @example
    #   user.increment_bitfield :column, :daily, :monthly
    #
    # @param [ Symbol ] column     name of the column these fields are in
    # @param [ Symbol ] field(s)   name of the field(s) to reset
    def increment_bitfields column_name, *fields
      mask = self.class.increment_mask_for column_name, *fields
      self[column_name] = self[column_name] += mask
      save
    end
    alias :increment_bitfield :increment_bitfields
    
    private
    
    # self[column_name].to_s(2)                -- converts integer to binary string
    # self[column_name].to_s(2)[filum]         -- selects range or integer from string
    # self[column_name].to_s(2)[filum].to_i(2) -- converts it back to an integer
    def get_bits_for(column, filum)
      return nil if self[column].nil?
      length     = self.class.bitfield_size column
      bit_string = self[column].to_i.to_s(2)
      
      sprintf("%0#{length}d", bit_string)[filum].to_i(2)
    end

    def set_bits_for(column, filum, value)
      length     = self.class.bitfield_size column
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