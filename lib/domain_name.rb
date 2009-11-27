#
# = DomainName
#
# Domain Name parser based on the Public Suffix List
#
#
# Category::    Net
# Package::     DomainName
# Author::      Simone Carletti <weppos@weppos.net>
# License::     MIT License
#
#--
#
#++


require 'domain_name/version'
require 'domain_name/errors'
require 'domain_name/rule'
require 'domain_name/rule_list'


class DomainName

  NAME            = 'DomainName'
  GEM             = 'domain_name'
  AUTHORS         = ['Simone Carletti <weppos@weppos.net>']


  attr_reader :name


  def initialize(name, &block)
    @name = name
    yield(self) if block_given?
  end  
  
  def labels
    to_s.split(".").reverse
  end

  def to_s
    name.to_s
  end


  def rule
    @rule ||= RuleList.default.find(self)
  end

  def rule!
    rule  || raise(Error, "The domain cannot be found in the TLD definition file")
  end


  def tld
    parse
    @tld
  end

  def sld
    parse
    @sld
  end
  alias :domain :tld

  def trd
    parse
    @trd
  end
  alias :subdomain :trd


  protected

    def parse
      return self if @parsed
      full, tld = rule!.decompose(self)

      # If we have 0 parts left, there is just a tld and no domain or subdomain
      # If we have 1 part, it's the domain, and there is no subdomain
      # If we have 2+ parts, the last part is the domain, the other parts (combined) are the subdomain
      parts   = full.split(".")
      @tld    = tld
      @sld    = parts.empty? ? nil : parts.pop
      @trd    = parts.empty? ? nil : parts.join(".")

      @parsed = true
      self
    end


  # Returns whether <tt>domain</tt> is a valid domain.
  #
  #   DomainName.valid?("google.com")
  #   # => true
  #   
  #   DomainName.valid?("www.google.com")
  #   # => true
  #   
  #   DomainName.valid?("http://www.google.com")
  #   # => false
  #   
  #   DomainName.valid?("x.yz")
  #   # => false
  #
  def self.valid?(domain)
    !new(domain).rule.nil?
  end

  # Parses <tt>domain</tt> and returns a new <tt>DomainName</tt> instance.
  #
  #   DomainName.parse("google.com")
  #   # => #<DomainName ...>
  #   
  #   DomainName.parse("www.google.com")
  #   # => #<DomainName ...>
  #   
  #   DomainName.parse("http://www.google.com")
  #   # => raises
  #   
  #   DomainName.parse("x.yz")
  #   # => raises
  #
  # ==== Raises
  #
  # DomainName::Error:: if <tt>domain</tt> is not a valid domain
  #
  def self.parse(domain)
     new(domain) { |d| d.rule! }
  end

end
