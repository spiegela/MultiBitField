# MultiBitField #

## Description ##

MultiBitField creates convenience methods for using multiple filum bit-fields with ActiveRecord.

I'm sure the first question might be: "Why?"  I assure you there are good reasons, but it will be a pretty specific need.  I'll try to show a couple of ways that I use this technique, so you can decide if it's useful for you.

MultiBitField extends an integer field of the database, and allows the user to specify multiple columns on that field.

Other plugins have leveraged this technique to store multiple boolean flags in a single database field.  While that's certainly possible with this tool, it really better for storing larger values like settings or counters.

I've found it useful sorting or comparing these types of fields.  For instance, you may have daily, weekly and monthly counters, and want to sort on this combination.  The order of the fields applys weight to each, so it should be chosen with care.

## Example ##

Say you have daily, weekly and monthly counters:

 Value     | Daily    | Weekly  | Monthly  |  All columns together 
 --------: | ------:  | ------: | -------: | :--------------------:
 bits      | 00011    | 00101   | 00001    |  000110010100001      
 values    | 3        | 5       | 1        |  3_233                
 weighted  | 3072     | 160     | 1        |  -                    
 maxval    | 31       | 31      | 31       |  32_767               
 
If this model is now sorted in ascending order, it'll sort first by day, then by week and then by month.  You could also compare counters with a paired "limit" field.

These methods only require an integer attribute (any ORM will do.)  Here's how we'd set this up:

```ruby
  class User < ActiveRecord::Base
    has_bit_field :counter, :daily_count => 0..4, :weekly_count => 5..9, :monthly_count => 10..14
	has_bit_field :limit,   :daily_limit => 0..4, :weekly_limit => 5..9, :monthly_limit => 10..14
  end
```

this provides the following methods:

```ruby
person = Person.new :daily => 3, :weekly => 5, :monthly => 1
person.daily 
=> 3
person.counter
=> 3233

person = Person.new :counter => 3233
person.monthly
=> 1
person.weekly
=> 5
person.monthly = 4
person.counter
=> 3236
```

We can inspsect what this bitstring looks like to converting it like so:

```ruby
person.counter.to_s(2)
-> 000110010100100

```

We also provide convenient methods for resetting and incrementing fields.  These methods require active-record and active-relation since they use the "update_attributes" and "update_all" methods.

When only the columnn name is supplied, it will increment or reset all of the fields.

```ruby
peron.reset(:counter, :daily)
person.daily
=> 0
person.monthly
=> 4

person.reset(:counter)
person.daily
=> 0
person.monthly
=> 0

person.increment(:counter, :daily)
person.daily
=> 1

person.increment(:counter)
person.daily
=> 2
person.monthly
=> 1

person.reset(:counter, :daily, :monthly)
person.daily
=> 0
person.monthly
=> 0
```

The same thing works with bulk assignment:

```ruby
[person1.daily, person2.daily]
=> [15, 23]

Person.reset :counter, :daily
[person1.daily, person2.daily]
=> [0, 0]

Person.increment :counter, :daily
=> [1, 1]
```

By the way, these methods all work with your chainable active-relation query methods!

```ruby
Person.where(:daily => 0).increment_bitfield(:counter, :daily)
```

We also support some cool counting features -- be sure to admire the nice clean SQL:

```ruby
Person.count_by(:counter, :monthly)
(0.4ms)  SELECT count(id) as daily_count, (counter & 31744)/1024 as daily FROM "people" GROUP BY daily
=> [{"daily_count" => 2, "daily" => 5}, {"daily_count" => 3, "daily" => 1}]
```

One limitation you should be aware of:

Since this technique pins the counters/limits to specific bits, you will need to plan the size of integer you intend to store in each field.  For instance, if you need numbers 0-7, you can store that in 3 bits, if you need 0-31, you'll need 5 bits, etc.

##Todo

I intend to add some more methods in the models for the following features:

  * Add comparison methods between bitfields on the same column, or between multiple columns
  * Investigate if there's a use for right/left bit shifting

Author:: Aaron Spiegel
Copyright:: Copyright (c) 2012 Aaron Spiegel
License:: MIT License (http://www.opensource.org/licenses/mit-license.php)
