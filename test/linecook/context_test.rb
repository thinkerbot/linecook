require File.expand_path('../../test_helper', __FILE__)
require 'linecook/context'

class ContextTest < Test::Unit::TestCase
  Context = Linecook::Context

  class Subclass < Context
  end

  module A
    def a
      :a
    end
  end

  #
  # _singleton_class_ test
  #

  def test__singleton_class__returns_singleton_class_for_context
    a = Context.new
    b = Context.new

    def a.singleton_m
    end

    assert a._singleton_class_.public_instance_methods.include?(:singleton_m)
    assert !b._singleton_class_.public_instance_methods.include?(:singleton_m)
  end

  #
  # _class_ test
  #

  def test__class__returns_class_for_context
    assert_equal Context, Context.new._class_
    assert_equal Subclass, Subclass.new._class_
  end

  #
  # _extend_ test
  #

  def test__extend__extends_context_with_module
    context = Context.new
    assert_raises(NoMethodError) { context.a }
    context._extend_ A
    assert_equal :a, context.a

    context = Context.new
    assert_raises(NoMethodError) { context.a }
  end

  #
  # _clone_ test
  #

  def test__clone__inherits_modules
    context = Context.new
    context._extend_ A
    clone = context._clone_
    assert_equal :a, clone.a
  end

  def test__clone__inherits_singleton_methods
    skip "unsupported: http://redmine.ruby-lang.org/issues/5582"
    context = Context.new

    def context.a
      :a
    end

    clone = context._clone_
    assert_equal :a, clone.a
  end
end