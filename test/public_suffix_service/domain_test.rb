require 'test_helper'

class PublicSuffixService::DomainTest < Test::Unit::TestCase

  def setup
    @klass = PublicSuffixService::Domain
  end

  def test_domain_to_lables
    assert_equal %w{com live spaces someone},       PublicSuffixService::Domain.domain_to_labels('someone.spaces.live.com')
    assert_equal %w{com zoho wiki leontina23samiko}, PublicSuffixService::Domain.domain_to_labels('leontina23samiko.wiki.zoho.com')
  end


  def test_initialize_with_tld
    domain = @klass.new("com")
    assert_equal "com",     domain.tld
    assert_equal nil,       domain.sld
    assert_equal nil,       domain.trd
  end

  def test_initialize_with_tld_and_sld
    domain = @klass.new("com", "google")
    assert_equal "com",     domain.tld
    assert_equal "google",  domain.sld
    assert_equal nil,       domain.trd
  end

  def test_initialize_with_tld_and_sld_and_trd
    domain = @klass.new("com", "google", "www")
    assert_equal "com",     domain.tld
    assert_equal "google",  domain.sld
    assert_equal "www",     domain.trd
  end


  def test_to_s
    assert_equal "com",             @klass.new("com").to_s
    assert_equal "google.com",      @klass.new("com", "google").to_s
    assert_equal "www.google.com",  @klass.new("com", "google", "www").to_s
  end

  def test_to_a
    assert_equal [nil, nil, "com"],         @klass.new("com").to_a
    assert_equal [nil, "google", "com"],    @klass.new("com", "google").to_a
    assert_equal ["www", "google", "com"],  @klass.new("com", "google", "www").to_a
  end


  def test_tld
    assert_equal "com", @klass.new("com", "google", "www").tld
  end

  def test_sld
    assert_equal "google", @klass.new("com", "google", "www").sld
  end

  def test_tld
    assert_equal "www", @klass.new("com", "google", "www").trd
  end


  def test_name
    assert_equal "com",             @klass.new("com").name
    assert_equal "google.com",      @klass.new("com", "google").name
    assert_equal "www.google.com",  @klass.new("com", "google", "www").name
  end

  def test_domain
    assert_equal nil, @klass.new("com").domain
    assert_equal nil, @klass.new("zip").domain
    assert_equal "google.com", @klass.new("com", "google").domain
    assert_equal "google.zip", @klass.new("zip", "google").domain
    assert_equal "google.com", @klass.new("com", "google", "www").domain
    assert_equal "google.zip", @klass.new("zip", "google", "www").domain
  end

  def test_subdomain
    assert_equal nil, @klass.new("com").subdomain
    assert_equal nil, @klass.new("zip").subdomain
    assert_equal nil, @klass.new("com", "google").subdomain
    assert_equal nil, @klass.new("zip", "google").subdomain
    assert_equal "www.google.com", @klass.new("com", "google", "www").subdomain
    assert_equal "www.google.zip", @klass.new("zip", "google", "www").subdomain
  end

  def test_rule
    assert_equal nil,                                      @klass.new("zip").rule
    assert_equal PublicSuffixService::Rule.factory("com"), @klass.new("com").rule
    assert_equal PublicSuffixService::Rule.factory("com"), @klass.new("com", "google").rule
    assert_equal PublicSuffixService::Rule.factory("com"), @klass.new("com", "google", "www").rule
  end


  def test_domain_question
    assert  @klass.new("com", "google").domain?
    assert  @klass.new("zip", "google").domain?
    assert  @klass.new("com", "google", "www").domain?
    assert !@klass.new("com").domain?
  end

  def test_subdomain_question
    assert  @klass.new("com", "google", "www").subdomain?
    assert  @klass.new("zip", "google", "www").subdomain?
    assert !@klass.new("com").subdomain?
    assert !@klass.new("com", "google").subdomain?
  end

  def test_is_a_domain_question
    assert  @klass.new("com", "google").is_a_domain?
    assert  @klass.new("zip", "google").is_a_domain?
    assert !@klass.new("com", "google", "www").is_a_domain?
    assert !@klass.new("com").is_a_domain?
  end

  def test_is_a_subdomain_question
    assert  @klass.new("com", "google", "www").is_a_subdomain?
    assert  @klass.new("zip", "google", "www").is_a_subdomain?
    assert !@klass.new("com").is_a_subdomain?
    assert !@klass.new("com", "google").is_a_subdomain?
  end

  def test_valid_question
    assert  @klass.new("com").valid?
    assert  @klass.new("com", "google").valid?
    assert  @klass.new("com", "google", "www").valid?
    assert !@klass.new("zip").valid?
    assert !@klass.new("zip", "google").valid?
    assert !@klass.new("zip", "google", "www").valid?
  end

  def test_valid_domain_question
    assert  @klass.new("com", "google").valid_domain?
    assert !@klass.new("zip", "google").valid_domain?
    assert  @klass.new("com", "google", "www").valid_domain?
    assert !@klass.new("com").valid_domain?
  end

  def test_valid_subdomain_question
    assert  @klass.new("com", "google", "www").valid_subdomain?
    assert !@klass.new("zip", "google", "www").valid_subdomain?
    assert !@klass.new("com").valid_subdomain?
    assert !@klass.new("com", "google").valid_subdomain?
  end

end
