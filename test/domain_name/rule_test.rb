require 'test_helper'

class RuleTest < Test::Unit::TestCase

  def test_factory_should_return_rule_normal
    rule = DomainName::Rule.factory("verona.it")
    assert_instance_of DomainName::Rule::Normal, rule
  end

  def test_factory_should_return_rule_exception
    rule = DomainName::Rule.factory("!british-library.uk")
    assert_instance_of DomainName::Rule::Exception, rule
  end

  def test_factory_should_return_rule_wildcard
    rule = DomainName::Rule.factory("*.aichi.jp")
    assert_instance_of DomainName::Rule::Wildcard, rule
  end

end


class RuleBaseTest < Test::Unit::TestCase

  class ::DomainName::Rule::Test < ::DomainName::Rule::Base
  end

  def setup
    @klass = DomainName::Rule::Base
  end


  def test_initialize
    rule = @klass.new("verona.it")
    assert_instance_of @klass,          rule

    assert_equal :base,                 rule.type
    assert_equal "verona.it",           rule.name
    assert_equal "verona.it",           rule.value
    assert_equal %w(verona it).reverse, rule.labels
  end

  def test_equality_with_self
    rule = DomainName::Rule::Base.new("foo")
    assert_equal rule, rule
  end

  def test_equality_with_internals
    assert_equal      @klass.new("foo"), @klass.new("foo")
    assert_not_equal  @klass.new("foo"), @klass.new("bar")
    assert_not_equal  @klass.new("foo"), DomainName::Rule::Test.new("bar")
    assert_not_equal  @klass.new("foo"), Class.new { def name; foo; end }.new
  end


  def test_match
    assert  @klass.new("uk").match?(domain_name("google.uk"))
    assert !@klass.new("gk").match?(domain_name("google.uk"))
    assert !@klass.new("google").match?(domain_name("google.uk"))
    assert  @klass.new("uk").match?(domain_name("google.co.uk"))
    assert !@klass.new("gk").match?(domain_name("google.co.uk"))
    assert !@klass.new("co").match?(domain_name("google.co.uk"))
    assert  @klass.new("co.uk").match?(domain_name("google.co.uk"))
    assert !@klass.new("uk.co").match?(domain_name("google.co.uk"))
    assert !@klass.new("go.uk").match?(domain_name("google.co.uk"))
  end

  def test_length
    assert_raise(NotImplementedError) { @klass.new("com").length }
  end

  def test_parts
    assert_raise(NotImplementedError) { @klass.new("com").parts }
  end

  def test_decompose
    assert_raise(NotImplementedError) { @klass.new("com").decompose(DomainName.new("google.com")) }
  end

end


class RuleNormalTest < Test::Unit::TestCase

  def setup
    @klass = DomainName::Rule::Normal
  end


  def test_initialize
    rule = @klass.new("verona.it")
    assert_instance_of @klass,              rule
    assert_equal :normal,                   rule.type
    assert_equal "verona.it",               rule.name
    assert_equal "verona.it",               rule.value
    assert_equal %w(verona it).reverse,     rule.labels
  end


  def test_match
    assert  @klass.new("uk").match?(domain_name("google.uk"))
    assert !@klass.new("gk").match?(domain_name("google.uk"))
    assert !@klass.new("google").match?(domain_name("google.uk"))
    assert  @klass.new("uk").match?(domain_name("google.co.uk"))
    assert !@klass.new("gk").match?(domain_name("google.co.uk"))
    assert !@klass.new("co").match?(domain_name("google.co.uk"))
    assert  @klass.new("co.uk").match?(domain_name("google.co.uk"))
    assert !@klass.new("uk.co").match?(domain_name("google.co.uk"))
    assert !@klass.new("go.uk").match?(domain_name("google.co.uk"))
  end

  def test_length
    assert_equal 1, @klass.new("com").length
    assert_equal 2, @klass.new("co.com").length
    assert_equal 3, @klass.new("mx.co.com").length
  end

  def test_parts
    assert_equal %w(com), @klass.new("com").parts
    assert_equal %w(co com), @klass.new("co.com").parts
    assert_equal %w(mx co com), @klass.new("mx.co.com").parts
  end

  def test_decompose
    assert_equal %w(google com), @klass.new("com").decompose(DomainName.new("google.com"))
    assert_equal %w(foo.google com), @klass.new("com").decompose(DomainName.new("foo.google.com"))
  end

end


class RuleExceptionTest < Test::Unit::TestCase

  def setup
    @klass = DomainName::Rule::Exception
  end


  def test_initialize
    rule = @klass.new("!british-library.uk")
    assert_instance_of @klass,                    rule
    assert_equal :exception,                      rule.type
    assert_equal "!british-library.uk",           rule.name
    assert_equal "british-library.uk",            rule.value
    assert_equal %w(british-library uk).reverse,  rule.labels
  end


  def test_match
    assert  @klass.new("!uk").match?(domain_name("google.co.uk"))
    assert !@klass.new("!gk").match?(domain_name("google.co.uk"))
    assert  @klass.new("!co.uk").match?(domain_name("google.co.uk"))
    assert !@klass.new("!go.uk").match?(domain_name("google.co.uk"))
    assert  @klass.new("!british-library.uk").match?(domain_name("british-library.uk"))
    assert !@klass.new("!british-library.uk").match?(domain_name("google.co.uk"))
  end

  def test_length
    assert_equal 1, @klass.new("!british-library.uk").length
    assert_equal 2, @klass.new("!foo.british-library.uk").length
  end

  def test_parts
    assert_equal %w(uk), @klass.new("!british-library.uk").parts
    assert_equal %w(tokyo jp), @klass.new("!metro.tokyo.jp").parts
  end

  def test_decompose
    assert_equal %w(british-library uk), @klass.new("!british-library.uk").decompose(DomainName.new("british-library.uk"))
    assert_equal %w(foo.british-library uk), @klass.new("!british-library.uk").decompose(DomainName.new("foo.british-library.uk"))
  end

end


class RuleWildcardTest < Test::Unit::TestCase

  def setup
    @klass = DomainName::Rule::Wildcard
  end


  def test_initialize
    rule = @klass.new("*.aichi.jp")
    assert_instance_of @klass,              rule
    assert_equal :wildcard,                 rule.type
    assert_equal "*.aichi.jp",              rule.name
    assert_equal "aichi.jp",                rule.value
    assert_equal %w(aichi jp).reverse,      rule.labels
  end


  def test_match
    assert  @klass.new("*.uk").match?(domain_name("google.uk"))
    assert  @klass.new("*.uk").match?(domain_name("google.co.uk"))
    assert  @klass.new("*.co.uk").match?(domain_name("google.co.uk"))
    assert !@klass.new("*.go.uk").match?(domain_name("google.co.uk"))
  end

  def test_length
    assert_equal 2, @klass.new("*.uk").length
    assert_equal 3, @klass.new("*.co.uk").length
  end

  def test_parts
    assert_equal %w(uk), @klass.new("*.uk").parts
    assert_equal %w(co uk), @klass.new("*.co.uk").parts
  end

  def test_decompose
    assert_equal %w(google co.uk), @klass.new("*.uk").decompose(DomainName.new("google.co.uk"))
    assert_equal %w(foo.google co.uk), @klass.new("*.uk").decompose(DomainName.new("foo.google.co.uk"))
  end

end
