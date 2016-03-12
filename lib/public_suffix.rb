#
# Public Suffix
#
# Domain name parser based on the Public Suffix List.
#
# Copyright (c) 2009-2016 Simone Carletti <weppos@weppos.net>
#

require 'public_suffix/domain'
require 'public_suffix/version'
require 'public_suffix/errors'
require 'public_suffix/rule'
require 'public_suffix/list'

module PublicSuffix

  DOT   = ".".freeze
  BANG  = "!".freeze
  STAR  = "*".freeze


  # Parses +name+ and returns the {PublicSuffix::Domain} instance.
  #
  # @example Parse a valid domain
  #   PublicSuffix.parse("google.com")
  #   # => #<PublicSuffix::Domain ...>
  #
  # @example Parse a valid subdomain
  #   PublicSuffix.parse("www.google.com")
  #   # => #<PublicSuffix::Domain ...>
  #
  # @example Parse a fully qualified domain
  #   PublicSuffix.parse("google.com.")
  #   # => #<PublicSuffix::Domain ...>
  #
  # @example Parse a fully qualified domain (subdomain)
  #   PublicSuffix.parse("www.google.com.")
  #   # => #<PublicSuffix::Domain ...>
  #
  # @example Parse an invalid domain
  #   PublicSuffix.parse("x.yz")
  #   # => PublicSuffix::DomainInvalid
  #
  # @example Parse an URL (not supported, only domains)
  #   PublicSuffix.parse("http://www.google.com")
  #   # => PublicSuffix::DomainInvalid
  #
  #
  # @param  [String, #to_s] name The domain name or fully qualified domain name to parse.
  # @param  [PublicSuffix::List] list The rule list to search, defaults to the default {PublicSuffix::List}
  # @param  [Boolean] include_private
  # @return [PublicSuffix::Domain]
  #
  # @raise [PublicSuffix::Error]
  #   If domain is not a valid domain.
  # @raise [PublicSuffix::DomainNotAllowed]
  #   If a rule for +domain+ is found, but the rule doesn't allow +domain+.
  def self.parse(name, list: List.default, include_private: true)
    what = normalize(name)
    raise what if what.is_a?(DomainInvalid)

    rule = list.find(what, include_private: include_private)
    if rule.nil?
      raise DomainInvalid, "`#{what}` is not a valid domain"
    end
    if rule.decompose(what).last.nil?
      raise DomainNotAllowed, "`#{what}` is not allowed according to Registry policy"
    end

    decompose(what, rule)
  end

  # Checks whether +domain+ is assigned and allowed, without actually parsing it.
  #
  # This method doesn't care whether domain is a domain or subdomain.
  # The validation is performed using the default {PublicSuffix::List}.
  #
  # @example Validate a valid domain
  #   PublicSuffix.valid?("example.com")
  #   # => true
  #
  # @example Validate a valid subdomain
  #   PublicSuffix.valid?("www.example.com")
  #   # => true
  #
  # @example Validate a not-listed domain
  #   PublicSuffix.valid?("example.tldnotlisted")
  #   # => true
  #
  # @example Validate a not-allowed domain
  #   PublicSuffix.valid?("example.do")
  #   # => false
  #   PublicSuffix.valid?("www.example.do")
  #   # => true
  #
  # @example Validate a fully qualified domain
  #   PublicSuffix.valid?("google.com.")
  #   # => true
  #   PublicSuffix.valid?("www.google.com.")
  #   # => true
  #
  # @example Check an URL (which is not a valid domain)
  #   PublicSuffix.valid?("http://www.example.com")
  #   # => false
  #
  #
  # @param  [String, #to_s] name The domain name or fully qualified domain name to validate.
  # @param  [Boolean] include_private
  # @return [Boolean]
  def self.valid?(name, list: List.default, include_private: true)
    what = normalize(name)
    return false if what.is_a?(DomainInvalid)

    rule = List.default.find(what, include_private: include_private)
    !rule.nil? && rule.allow?(what)
    !rule.nil? && !rule.decompose(what).last.nil?
  end

  # Attempt to parse the name and returns the domain, if valid.
  #
  # This method doesn't raise. Instead, it returns nil if the domain is not valid for whatever reason.
  #
  # @param  [String, #to_s] name The domain name or fully qualified domain name to parse.
  # @param  [PublicSuffix::List] list The rule list to search, defaults to the default {PublicSuffix::List}
  # @param  [Boolean] include_private
  # @return [String]
  def self.domain(name, list: List.default, include_private: true)
    parse(name, list: list, include_private: include_private).domain
  rescue PublicSuffix::Error
    nil
  end


  private

  def self.decompose(name, rule)
    left, right = rule.decompose(name)

    parts = left.split(DOT)
    # If we have 0 parts left, there is just a tld and no domain or subdomain
    # If we have 1 part  left, there is just a tld, domain and not subdomain
    # If we have 2 parts left, the last part is the domain, the other parts (combined) are the subdomain
    tld = right
    sld = parts.empty? ? nil : parts.pop
    trd = parts.empty? ? nil : parts.join(DOT)

    Domain.new(tld, sld, trd)
  end

  # Pretend we know how to deal with user input.
  def self.normalize(name)
    name = name.to_s.dup
    name.strip!
    name.chomp!(DOT)
    name.downcase!

    return DomainInvalid.new("Name is blank") if name.empty?
    return DomainInvalid.new("Name starts with a dot") if name.start_with?(DOT)
    return DomainInvalid.new("%s is not expected to contain a scheme" % name) if name.include?("://")
    name
  end

end
