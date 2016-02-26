# Workflow Orchestrator [![Build Status](https://travis-ci.org/lorefnon/workflow-orchestrator.svg?branch=master)](https://travis-ci.org/lorefnon/workflow-orchestrator)[![Dependency Status](https://gemnasium.com/lorefnon/workflow-orchestrator.svg)](https://gemnasium.com/lorefnon/workflow-orchestrator)[![Stories in Ready](https://badge.waffle.io/lorefnon/workflow-orchestrator.png?label=ready&title=Ready)](https://waffle.io/lorefnon/workflow-orchestrator)[![Inline docs](http://inch-ci.org/github/lorefnon/workflow-orchestrator.svg?branch=master)](http://inch-ci.org/github/lorefnon/workflow-orchestrator)

A ruby DSL for modeling business logic as [Finite State Machines](https://en.wikipedia.org/wiki/Finite-state_machine).

The aim of this library is to make the expression of these concepts as clear as possible, utilizing the expressiveness of ruby language, and using similar terminology as found in state machine theory.

## Concepts

- **State:** A workflow is in exactly one state at a time. State may optionally be persisted using ActiveRecord.
- **State transition:** Change of state can be observed and intercepted
- **Events:** Events cause state transitions to occur
- **Actions:** Actions constitute of parts of our business logic which are executed in response to state transitions.

We can hook into states when they are entered, and exited from, and we can cause transitions to fail (guards), and we can hook in to every transition that occurs ever for whatever reason we can come up with.

## Example

Let's say we're modeling article submission from journalists. An article
is written, then submitted. When it's submitted, it's awaiting review.
Someone reviews the article, and then either accepts or rejects it.
Here is the expression of this workflow using the API:

```ruby
class Article
  include Workflow
  workflow do
    state :new do
      event :submit, :transitions_to => :awaiting_review
    end
    state :awaiting_review do
      event :review, :transitions_to => :being_reviewed
    end
    state :being_reviewed do
      event :accept, :transitions_to => :accepted
      event :reject, :transitions_to => :rejected
    end
    state :accepted
    state :rejected
  end
end
```

Nice, isn't it!

Note: the first state in the definition (`:new` in the example, but you
can name it as you wish) is used as the initial state - newly created
objects start their life cycle in that state.

Let's create an article instance and check in which state it is:

```ruby
article = Article.new
article.accepted? # => false
article.new? # => true
```

You can also access the whole `current_state` object including the list
of possible events and other meta information:

```ruby
article.current_state
# => #<Workflow::State:0x007fa1ab36f750
#  @events={:submit=>#<Workflow::Event:0x007fa1ab36f638 @action=nil, @meta={}, @name=:submit, @transitions_to=:awaiting_review>},
#  @meta={},
#  @name=:new
```

On Ruby 1.9 and above, you can check whether a state comes before or
after another state (by the order they were defined):

```ruby
article.current_state.name
# => being_reviewed
article.current_state < :accepted
# => true
article.current_state >= :accepted
# => false
article.current_state.between? :awaiting_review, :rejected
# => true
```

Now we can call the submit event, which transitions to the
<tt>:awaiting_review</tt> state:

```ruby
article.submit!
article.awaiting_review? # => true
```

Events are actually instance methods on a workflow, and depending on the
state you're in, you'll have a different set of events used to
transition to other states.

It is also easy to check, if a certain transition is possible from the
current state. `article.can_submit?` checks if there is a `:submit`
event (transition) defined for the current state.


Installation
------------

    `gem install workflow`
    
    `include Workflow` in your model.

If you're using ActiveRecord, Workflow will by default use a "workflow_state" column on your model.

**Important**: If you're interested in graphing your workflow state machine, you will also need to
install the `activesupport` and `ruby-graphviz` gems.

Transition event handler
------------------------

The best way is to use convention over configuration and to define a
method with the same name as the event. Then it is automatically invoked
when event is raised. For the Article workflow defined earlier it would
be:

```ruby
class Article
  def reject
    puts 'sending email to the author explaining the reason...'
  end
end
```

`article.review!; article.reject!` will cause state transition to
`being_reviewed` state, persist the new state (if integrated with
ActiveRecord), invoke this user defined `reject` method and finally
persist the `rejected` state.

Note: on successful transition from one state to another the workflow
gem immediately persists the new workflow state with `update_column()`,
bypassing any ActiveRecord callbacks including `updated_at` update.
This way it is possible to deal with the validation and to save the
pending changes to a record at some later point instead of the moment
when transition occurs.

You can also define event handler accepting/requiring additional
arguments:

```ruby
class Article
  def review(reviewer = '')
    puts "[#{reviewer}] is now reviewing the article"
  end
end

article2 = Article.new
article2.submit!
article2.review!('Homer Simpson') # => [Homer Simpson] is now reviewing the article
```

### The old, deprecated way

The old way, using a block is still supported but deprecated:

```ruby
event :review, :transitions_to => :being_reviewed do |reviewer|
  # store the reviewer
end
```

We've noticed, that mixing the list of events and states with the blocks
invoked for particular transitions leads to a bumpy and poorly readable code
due to a deep nesting. We tried (and dismissed) lambdas for this. Eventually
we decided to invoke an optional user defined callback method with the same
name as the event (convention over configuration) as explained before.


Integration with ActiveRecord
-----------------------------

Workflow library can handle the state persistence fully automatically. You
only need to define a string field on the table called `workflow_state`
and include the workflow mixin in your model class as usual:

```ruby
class Order < ActiveRecord::Base
  include Workflow
  workflow do
    # list states and transitions here
  end
end
```

On a database record loading all the state check methods e.g.
`article.state`, `article.awaiting_review?` are immediately available.
For new records or if the `workflow_state` field is not set the state
defaults to the first state declared in the workflow specification. In
our example it is `:new`, so `Article.new.new?` returns true and
`Article.new.approved?` returns false.

At the end of a successful state transition like `article.approve!` the
new state is immediately saved in the database.

You can change this behaviour by overriding `persist_workflow_state`
method.

### Scopes

Workflow library also adds automatically generated scopes with names based on
states names:

```ruby
class Order < ActiveRecord::Base
  include Workflow
  workflow do
    state :approved
    state :pending
  end
end

# returns all orders with `approved` state
Order.with_approved_state

# returns all orders except for those having `approved` state
Order.without_approved_state

# returns all orders except for those having `pending` state
Order.without_pending_state
```


### Custom workflow database column

[meuble](http://imeuble.info/) contributed a solution for using
custom persistence column easily, e.g. for a legacy database schema:

```ruby
class LegacyOrder < ActiveRecord::Base
  include Workflow

  workflow_column :foo_bar # use this legacy database column for
                           # persistence
end
```

You can also set the column name inline into the workflow block:

```ruby
class LegacyOrder < ActiveRecord::Base
  include Workflow

  workflow :foo_bar do
    state :approved
    state :pending
  end
end
```

### Single table inheritance

Single table inheritance is also supported. Descendant classes can either
inherit the workflow definition from the parent or override with its own
definition.

Custom workflow state persistence
---------------------------------

If you do not use a relational database and ActiveRecord, you can still
integrate the workflow very easily. To implement persistence you just
need to override `load_workflow_state` and
`persist_workflow_state(new_value)` methods. Next section contains an example for
using CouchDB, a document oriented database.

[Tim Lossen](http://tim.lossen.de/) implemented support
for [remodel](http://github.com/tlossen/remodel) / [redis](http://github.com/antirez/redis)
key-value store.

Integration with CouchDB
------------------------

We are using the compact [couchtiny library](http://github.com/geekq/couchtiny)
here. But the implementation would look similar for the popular
couchrest library.

```ruby
require 'couchtiny'
require 'couchtiny/document'
require 'workflow'

class User < CouchTiny::Document
  include Workflow
  workflow do
    state :submitted do
      event :activate_via_link, :transitions_to => :proved_email
    end
    state :proved_email
  end

  def load_workflow_state
    self[:workflow_state]
  end

  def persist_workflow_state(new_value)
    self[:workflow_state] = new_value
    save!
  end
end
```

Please also have a look at
[the full source code](http://github.com/geekq/workflow/blob/master/test/couchtiny_example.rb).


Adapters to support other databases
-----------------------------------

I get a lot of requests to integrate persistence support for different
databases, object-relational adapters, column stores, document
databases.

To enable highest possible quality, avoid too many dependencies and to
avoid unneeded maintenance burden on the `workflow` core it is best to
implement such support as a separate gem.

Only support for the ActiveRecord will remain for the foreseeable
future. So Rails beginners can expect `workflow` to work with Rails out
of the box. Other already included adapters stay for a while but should
be extracted to separate gems.

If you want to implement support for your favorite ORM mapper or your
favorite NoSQL database, you just need to implement a module which
overrides the persistence methods `load_workflow_state` and
`persist_workflow_state`. Example:

```ruby
module Workflow
  module SuperCoolDb
    module InstanceMethods
      def load_workflow_state
        # Load and return the workflow_state from some storage.
        # You can use self.class.workflow_column configuration.
      end

      def persist_workflow_state(new_value)
        # save the new_value workflow state
      end
    end

    module ClassMethods
      # class methods of your adapter go here
    end

    def self.included(klass)
      klass.send :include, InstanceMethods
      klass.extend ClassMethods
    end
  end
end
```

The user of the adapter can use it then as:

```ruby
class Article
  include Workflow
  include Workflow::SuperCoolDb
  workflow do
    state :submitted
    # ...
  end
end
```

I can then link to your implementation from this README. Please let me
also know, if you need any interface beyond `load_workflow_state` and
`persist_workflow_state` methods to implement an adapter for your
favorite database.


Custom Versions of Existing Adapters
------------------------------------

Other adapters (such as a custom ActiveRecord plugin) can be selected by adding a `workflow_adapter` class method, eg.

```ruby
class Example < ActiveRecord::Base
  def self.workflow_adapter
    MyCustomAdapter
  end
  include Workflow

  # ...
end
```

(The above will include `MyCustomAdapter` *instead* of `Workflow::Adapter::ActiveRecord`.)


Accessing your workflow specification
-------------------------------------

You can easily reflect on workflow specification programmatically - for
the whole class or for the current object. Examples:

```ruby
article2.current_state.events # lists possible events from here
article2.current_state.events[:reject].transitions_to # => :rejected

Article.workflow_spec.states.keys
# => [:rejected, :awaiting_review, :being_reviewed, :accepted, :new]

Article.workflow_spec.state_names
# => [:rejected, :awaiting_review, :being_reviewed, :accepted, :new]

# list all events for all states
Article.workflow_spec.states.values.collect &:events
```

You can also store and later retrieve additional meta data for every
state and every event:

```ruby
class MyProcess
  include Workflow
  workflow do
    state :main, :meta => {:importance => 8}
    state :supplemental, :meta => {:importance => 1}
  end
end
puts MyProcess.workflow_spec.states[:supplemental].meta[:importance] # => 1
```

The workflow library itself uses this feature to tweak the graphical
representation of the workflow. See below.


Conditional event transitions
-----------------------------

Conditions can be a "method name symbol" with a corresponding instance method, a `proc` or `lambda` which are added to events, like so:

```ruby
    state :off do
      event :turn_on, :transition_to => :on,
                      :if => :sufficient_battery_level?

      event :turn_on, :transition_to => :low_battery,
                      :if => proc { |device| device.battery_level > 0 }
    end

    # corresponding instance method
    def sufficient_battery_level?
      battery_level > 10
    end
```

When calling a `device.can_<fire_event>?` check, or attempting a `device.<event>!`, each event is checked in turn:

* With no `:if` check, proceed as usual.
* If an `:if` check is present, proceed if it evaluates to true, or drop to the next event.
* If you've run out of events to check (eg. `battery_level == 0`), then the transition isn't possible.

Enum values or other custom values
-----------------------------------

If you don't want to store your state as a string column, you can specify the value associated with each state.  Yu can use an int (like an enum) or a shorter string, or whatever you want.

Just pass the "value" for the state as the second parameter to the "state" method.

    Class Foo < ActiveRecord::Base
      include Workflow
    
      workflow do
        state :one, 1 do
          event :increment, :transitions_to => :two
        end
        state :two, 2
        on_transition do |from, to, triggering_event, *event_args|
          Log.info "#{from} -> #{to}"
        end
      end
    end

Your database column will store the values 1, 2, etc.  But you'll still use the state symbols for querying.

    foo = Foo.create
    foo.current_state # => :one
    foo.workflow_state # => 1 #You really shouldn't use this column directly...
    foo.increment!
    foo.two? # => true
    foo.workflow_state # => true

Hopefully obvious, but if you ever change the value of a state, you'll need to do a migration/address existing records in your data store.  However you are free to change the "name" of a state, willy-nilly.

Advanced transition hooks
-------------------------

### `on_entry`/`on_exit`

We already had a look at the declaring callbacks for particular workflow
events. If you would like to react to all transitions to/from the same state
in the same way you can use the `on_entry`/`on_exit` hooks. You can either define it
with a block inside the workflow definition or through naming
convention, e.g. for the state :pending just define the method
`on_pending_exit(new_state, event, *args)` somewhere in your class.

### `on_transition`

If you want to be informed about everything happening everywhere, e.g. for
logging then you can use the universal `on_transition` hook:

```ruby
workflow do
  state :one do
    event :increment, :transitions_to => :two
  end
  state :two
  on_transition do |from, to, triggering_event, *event_args|
    Log.info "#{from} -> #{to}"
  end
end
```

Please also have a look at the [advanced end to end
example][advanced_hooks_and_validation_test].

[advanced_hooks_and_validation_test]: http://github.com/geekq/workflow/blob/master/test/advanced_hooks_and_validation_test.rb

### `on_error`

If you want to do custom exception handling internal to workflow, you can define an `on_error` hook in your workflow.
For example:

```ruby
workflow do
  state :first do
    event :forward, :transitions_to => :second
  end
  state :second

  on_error do |error, from, to, event, *args|
    Log.info "Exception(#error.class) on #{from} -> #{to}"
  end
end
```

If forward! results in an exception, `on_error` is invoked and the workflow stays in a 'first' state.  This capability
is particularly useful if your errors are transient and you want to queue up a job to retry in the future without
affecting the existing workflow state.

Note: this is not triggered by Workflow::NoTransitionAllowed exceptions.

### on_unavailable_transition

If you want to do custom handling when an unavailable transition is called, you can define an 'on_unavailable_transition' hook
in your workflow. For example

    workflow do
      state :first
      state :second do
        event :backward, :transitions_to => :first
      end

      on_unavailable_transition do |from, to_name, *args|
        Log.warn "Workflow: #{from} does not have #{to_name} available to it"
      end
    end

If backward! is called when in the `first` state, 'on_unavailable_transition' is invoked and workflow stays in a 'first' state.  This
example surpresses the Workflow::NoTransitionAllowed exception from being raised, if you still want it to be raised you can simply
call it yourself or return false.

This is particularly useful when you don't want a processes to be aborted due to the workflow being in an unexpected state.

### Guards

If you want to halt the transition conditionally, you can just raise an
exception in your [transition event handler](#transition_event_handler).
There is a helper called `halt!`, which raises the
Workflow::TransitionHalted exception. You can provide an additional
`halted_because` parameter.

```ruby
def reject(reason)
  halt! 'We do not reject articles unless the reason is important' \
    unless reason =~ /important/i
end
```

The traditional `halt` (without the exclamation mark) is still supported
too. This just prevents the state change without raising an
exception.

You can check `halted?` and `halted_because` values later.

### Hook order

The whole event sequence is as follows:

* `before_transition`
* event specific action
* `on_transition` (if action did not halt)
* `on_exit`
* PERSIST WORKFLOW STATE, i.e. transition
* `on_entry`
* `after_transition`


Multiple Workflows
------------------

I am frequently asked if it's possible to represent multiple "workflows"
in an ActiveRecord class.

The solution depends on your business logic and how you want to
structure your implementation.

### Use Single Table Inheritance

One solution can be to do it on the class level and use a class
hierarchy. You can use [single table inheritance][STI] so there is only
single `orders` table in the database. Read more in the chapter "Single
Table Inheritance" of the [ActiveRecord documentation][ActiveRecord].
Then you define your different classes:

```ruby
class Order < ActiveRecord::Base
  include Workflow
end

class SmallOrder < Order
  workflow do
    # workflow definition for small orders goes here
  end
end

class BigOrder < Order
  workflow do
    # workflow for big orders, probably with a longer approval chain
  end
end
```

### Individual workflows for objects

Another solution would be to connect different workflows to object
instances via metaclass, e.g.

```ruby
# Load an object from the database
booking = Booking.find(1234)

# Now define a workflow - exclusively for this object,
# probably depending on some condition or database field
if # some condition
  class << booking
    include Workflow
    workflow do
      state :state1
      state :state2
    end
  end
# if some other condition, use a different workflow
```

You can also encapsulate this in a class method or even put in some
ActiveRecord callback. Please also have a look at [the full working
example][multiple_workflow_test]!

[STI]: http://www.martinfowler.com/eaaCatalog/singleTableInheritance.html
[ActiveRecord]: http://api.rubyonrails.org/classes/ActiveRecord/Base.html
[multiple_workflow_test]: http://github.com/geekq/workflow/blob/master/test/multiple_workflows_test.rb


Documenting with diagrams
-------------------------

You can generate a graphical representation of the workflow for
a particular class for documentation purposes.
Use `Workflow::create_workflow_diagram(class)` in your rake task like:

```ruby
namespace :doc do
  desc "Generate a workflow graph for a model passed e.g. as 'MODEL=Order'."
  task :workflow => :environment do
    require 'workflow/draw'
    Workflow::Draw::workflow_diagram(ENV['MODEL'].constantize)
  end
end
```

About
-----

Workflow Orchestrator is maintained by [Lorefnon](https://lorefnon.me) along with [many contributors](https://github.com/lorefnon/workflow-orchestrator/graphs/contributors).

This project was derived (forked) from the gem [geekq/workflow](https://github.com/geekq/workflow) by Vladimir Dobriakov, which was forked from the original repo authored by Ryan Allen. Both appear to be unmaintained as of 2016. 

While it is largely compatible with geekq/workflow but breaking API changes will be introduced in coming versions. In addition, the intent is to extract the persistence and rails dependent features in different gems, leaving only the FSM management features in the core. 

History
-------

Copyright (c) 2016 Lorefnon

Copyright (c) 2010-2014 Vladimir Dobriakov

Copyright (c) 2008-2009 Vodafone

Copyright (c) 2007-2008 Ryan Allen, FlashDen Pty Ltd

Based on the work of Ryan Allen and Scott Barron

Licensed under MIT license, see the MIT-LICENSE file.
