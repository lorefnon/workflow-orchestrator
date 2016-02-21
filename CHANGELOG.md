# Changelog

### Release 1.3.1

* Removed support for Ruby < 2.0.0.
  If you still need older versions despite security issues and missing updates, you can continue using
  geekq/workflow 1.3.0 or older. In your Gemfile put

      gem 'workflow', '~> 1.2.0'

### Release 1.3.0

* Incorporated following pull requests from geekq/workflow :
  * [#172](https://github.com/geekq/workflow/pull/172) Add documentation for without_name_state scopes
  * [#112](https://github.com/geekq/workflow/pull/112) Negative class level and instance level scopes
  * [#115](https://github.com/geekq/workflow/pull/115) Use syntax highlighting in README
  * [#148](https://github.com/geekq/workflow/pull/148) Custom handling when an unavailable transition is called
  * [#157](https://github.com/geekq/workflow/pull/157) Small Correction in README
  * [#158](https://github.com/geekq/workflow/pull/158) Support for enumerated state values
  * [#160](https://github.com/geekq/workflow/pull/160) Do not attempt to draw metadata
* Improved callback method handling: #113 and #125

## Previous Releases (geekq/workflow)

### New in the version 1.2.0

* Fix issue #98 protected `on\_\*` callbacks in Ruby 2
* [#106](https://github.com/geekq/workflow/issues/106) Inherit exceptions from `StandardError` instead of `Exception`
* [#109](https://github.com/geekq/workflow/pull/109) Conditional event transitions, contributed by [damncabbage](http://robhoward.id.au/)
  Please note: this introduces incompatible changes to the meta data API, see also #131.
* New policy for supporting other databases - extract to separate
  gems. See the [README section above](#adapters-to-support-other-databases).
* [#111](https://github.com/geekq/workflow/pull/111) Custom Versions of Existing Adapters by [damncabbage](http://robhoward.id.au/)


### New in the version 1.1.0

* Tested with ActiveRecord 4.0 (Rails 4.0)
* Tested with Ruby 2.0
* automatically generated scopes with names based on state names
* clean workflow definition override for class inheritance - undefining
  the old convinience methods, s. <http://git.io/FZO02A>

### New in the version 1.0.0

* **Support to private/protected callback methods.**
  See also issues [#53](https://github.com/geekq/workflow/pull/53)
  and [#58](https://github.com/geekq/workflow/pull/58). With the new
  implementation:

  * callback methods can be hidden (non public): both private methods
    in the immediate class and protected methods somewhere in the class
    hierarchy are supported
  * no unintentional calls on `fail!` and other Kernel methods
  * inheritance hierarchy with workflow is supported

* using Rails' 3.1 `update_column` whenever available so only the
  workflow state column and not other pending attribute changes are
  saved on state transition. Fallback to `update_attribute` for older
  Rails and other ORMs. [commit](https://github.com/geekq/workflow/commit/7e091d8ded1aeeb0a86647bbf7d78ab3c9d0c458)

### New in the version 0.8.7

* switch from [jeweler][] to pure bundler for building gems

### New in the version 0.8.0

* check if a certain transition possible from the current state with
  `can_....?`
* fix `workflow_state` persistence for multiple_workflows example
* add `before_transition` and `after_transition` hooks as suggested by
  [kasperbn](https://github.com/kasperbn)

### New in the version 0.7.0

* fix issue#10 `Workflow::create_workflow_diagram` documentation and path
  escaping
* fix issue#7 workflow_column does not work STI (single table
  inheritance) ActiveRecord models
* fix issue#5 Diagram generation fails for models in modules

### New in the version 0.6.0

* enable multiple workflows by connecting workflow to object instances
  (using metaclass) instead of connecting to a class, s. "Multiple
  Workflows" section

### New in the version 0.5.0

* fix issue#3 change the behaviour of halt! to immediately raise an
  exception. See also http://github.com/geekq/workflow/issues/#issue/3

### New in the version 0.4.0

* completely rewritten the documentation to match my branch
* switch to [jeweler][] for building gems
* use [gemcutter][] for gem distribution
* every described feature is backed up by an automated test

[jeweler]: http://github.com/technicalpickles/jeweler
[gemcutter]: http://gemcutter.org/gems/workflow

### New in the version 0.3.0

Intermixing of transition graph definition (states, transitions)
on the one side and implementation of the actions on the other side
for a bigger state machine can introduce clutter.

To reduce this clutter it is now possible to use state entry- and
exit- hooks defined through a naming convention. For example, if there
is a state `:pending`, then instead of using a
block:

```ruby
state :pending do
  on_entry do
    # your implementation here
  end
end
```

you can hook in by defining method

```ruby
def on_pending_exit(new_state, event, *args)
  # your implementation here
end
```

anywhere in your class. You can also use a simpler function signature
like `def on_pending_exit(*args)` if your are not interested in
arguments.  Please note: `def on_pending_exit()` with an empty list
would not work.

If both a function with a name according to naming convention and the
`on_entry`/`on_exit` block are given, then only `on_entry`/`on_exit` block is used.
