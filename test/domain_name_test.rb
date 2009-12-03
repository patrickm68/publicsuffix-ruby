require 'test_helper'

class DomainNameTest < Test::Unit::TestCase

  def test_labels
    assert_equal %w(uk co google), domain_name("google.co.uk").labels
    assert_equal %w(uk google), domain_name("google.uk").labels
  end

  def test_to_s
    assert_equal "google.uk", domain_name("google.uk").to_s
    assert_equal "google.co.uk", domain_name("google.co.uk").to_s
  end


  def test_rule
    assert_kind_of DomainName::Rule::Base, domain_name("google.com").rule
  end

  def test_rule_missing
    assert_equal nil, domain_name("google.gzip").rule
  end

  def test_rule_bang
    assert_kind_of DomainName::Rule::Base, domain_name("google.com").rule!
  end

  def test_rule_bang_missing
    assert_raise(DomainName::Error) { domain_name("google.gzip").rule! } 
  end

end