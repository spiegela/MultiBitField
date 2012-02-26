require 'multi_bit_field/core_ext'

module MultiBitField  
  module ClassMethods
    # MultiBitField create convenience methods for using
    # multiple filum bit-fields with ActiveRecord.
    # Author:: Aaron Spiegel
    # Copyright:: Copyright (c) 2012 Aaron Spiegel
    # License:: MIT License (http://www.opensource.org/licenses/mit-license.php)
    #
    # MultiBitField extends an integer field of the database, and
    # allows the user to specify multiple columns on that field.
    # This can be useful when managing multiple boolean options (with single bit columns,)
    # or multiple bit counters.  This can be useful when sorting based on a combination of
    # fields.  For instance, you may have daily, weekly and monthly counters, and wan to
    # sort on each of these with greater weight given to the "daily" counts.  For this
    # usecase, you could specify the following columns:
    #
    #  +----------+---------+---------+---------+----------------------+
    #  |   daily  |  daily  |  weekly | monthly | all columns together |
    #  +----------+---------+---------+---------+----------------------+
    #  |   bits   |  00011  |  00101  | 00001   |    000110010100001   |
    #  |   values |    3    |    5    |    1    |        3_233         |
    #  | weighted |   3072  |   160   |    1    |           -          |
    #  |   maxval |   31    |   31    |   31    |       32_767         |
    #  +----------+---------+---------+---------+----------------------+
    #
    # As you can see, the individual counters can be used individually, or all as one
    # number.  This can be useful when doing sort operations.  The column order also changes
    # the relative weight of each.  This can be useful when sorting based on multiple
    # weighted fields, or comparing related values simply and efficiently.
    #
    # +has_bit_field :column, :fields
    #
    #   class User < ActiveRecord::Base
    #     has_bit_field :counter, :daily => 0..4, :weekly => 5..9, :monthly => 10..14
    #   end
    #
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

      raise "Attempted value: #{value} is too large for selected filum" \
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