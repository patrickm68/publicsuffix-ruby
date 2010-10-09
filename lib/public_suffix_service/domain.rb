#
# = Public Suffix Service
#
# Domain Name parser based on the Public Suffix List
#
#
# Category::    Net
# Package::     PublicSuffixService
# Author::      Simone Carletti <weppos@weppos.net>
# License::     MIT License
#
#--
#
#++


module PublicSuffixService

  class Domain

    # Splits a string into its possible labels
    # as a domain in reverse order from the input string.
    #
    # The input is not validated, but it is assumed to be a valid domain.
    #
    # @param  [String, #to_s] domain
    #   The domain name to split.
    #
    # @return [Array<String>]
    #
    # @example
    #
    #   domain_to_labels('google.com')
    #   # => ['com', 'google']
    #
    #   domain_to_labels('google.co.uk')
    #   # => ['uk', 'co', 'google']
    #
    def self.domain_to_labels(domain)
      domain.to_s.split(".").reverse
    end

    # Creates and returns a new {PublicSuffixService::Domain} instance.
    #
    # @overload initialize(tld)
    #   Initializes with a +tld+.
    #   @param [String] tld The TLD (extension)
    # @overload initialize(tld, sld)
    #   Initializes with a +tld+ and +sld+.
    #   @param [String] tld The TLD (extension)
    #   @param [String] sld The TRD (domain)
    # @overload initialize(tld, sld, trd)
    #   Initializes with a +tld+, +sld+ and +trd+.
    #   @param [String] tld The TLD (extension)
    #   @param [String] sld The SLD (domain)
    #   @param [String] tld The TRD (subdomain)
    #
    # @yield [self] Yields on self.
    # @yieldparam [PublicSuffixService::Domain] self The newly creates instance
    #
    # @example Initialize with a TLD
    #   PublicSuffixService::Domain.new("com")
    #   # => #<PublicSuffixService::Domain @tld="com">
    #
    # @example Initialize with a TLD and SLD
    #   PublicSuffixService::Domain.new("com", "example")
    #   # => #<PublicSuffixService::Domain @tld="com", @trd=nil>
    #
    # @example Initialize with a TLD, SLD and TRD
    #   PublicSuffixService::Domain.new("com", "example", "wwww")
    #   # => #<PublicSuffixService::Domain @tld="com", @trd=nil, @sld="example">
    #
    def initialize(*args, &block)
      @tld, @sld, @trd = args
      yield(self) if block_given?
    end

    # Returns a string representation of this object.
    #
    # @return [String]
    def to_s
      name
    end

    # Returns an array containing the domain parts.
    #
    # @return [Array<String, nil>]
    #
    # @example
    #
    #   PublicSuffixService::Domain.new("google.com").to_a
    #   # => [nil, "google", "com"]
    #
    #   PublicSuffixService::Domain.new("www.google.com").to_a
    #   # => [nil, "google", "com"]
    #
    def to_a
      [trd, sld, tld]
    end


    # Returns the Top Level Domain part, aka the extension.
    #
    # @return [String, nil]
    def tld
      @tld
    end

    # Returns the Second Level Domain part, aka the domain part.
    #
    # @return [String, nil]
    def sld
      @sld
    end

    # Returns the Third Level Domain part, aka the subdomain part.
    #
    # @return [String, nil]
    def trd
      @trd
    end


    # Returns the full domain name.
    #
    # @return [String]
    #
    # @example Gets the domain name of a domain
    #   PublicSuffixService::Domain.new("com", "google").name
    #   # => "google.com"
    #
    # @example Gets the domain name of a subdomain
    #   PublicSuffixService::Domain.new("com", "google", "www").name
    #   # => "www.google.com"
    #
    def name
      [trd, sld, tld].reject { |part| part.nil? }.join(".")
    end

    # Returns a domain-like representation of this object
    # if the object is a {#domain?}, <tt>nil</tt> otherwise.
    #
    #   PublicSuffixService::Domain.new("com").domain
    #   # => nil
    #
    #   PublicSuffixService::Domain.new("com", "google").domain
    #   # => "google.com"
    #
    #   PublicSuffixService::Domain.new("com", "google", "www").domain
    #   # => "www.google.com"
    #
    # This method doesn't validate the input. It handles the domain
    # as a valid domain name and simply applies the necessary transformations.
    #
    #   # This is an invalid domain
    #   PublicSuffixService::Domain.new("zip", "google").domain
    #   # => "google.zip"
    #
    # This method returns a FQD, not just the domain part.
    # To get the domain part, use <tt>#sld</tt> (aka second level domain).
    #
    #   PublicSuffixService::Domain.new("com", "google", "www").domain
    #   # => "google.com"
    #
    #   PublicSuffixService::Domain.new("com", "google", "www").sld
    #   # => "google"
    #
    # @return [String]
    #
    # @see #domain?
    # @see #subdomain
    #
    def domain
      return unless domain?
      [sld, tld].join(".")
    end

    # Returns a domain-like representation of this object
    # if the object is a {#subdomain?}, <tt>nil</tt> otherwise.
    #
    #   PublicSuffixService::Domain.new("com").subdomain
    #   # => nil
    #
    #   PublicSuffixService::Domain.new("com", "google").subdomain
    #   # => nil
    #
    #   PublicSuffixService::Domain.new("com", "google", "www").subdomain
    #   # => "www.google.com"
    #
    # This method doesn't validate the input. It handles the domain
    # as a valid domain name and simply applies the necessary transformations.
    #
    #   # This is an invalid domain
    #   PublicSuffixService::Domain.new("zip", "google", "www").subdomain
    #   # => "www.google.zip"
    #
    # This method returns a FQD, not just the domain part.
    # To get the domain part, use <tt>#tld</tt> (aka third level domain).
    #
    #   PublicSuffixService::Domain.new("com", "google", "www").subdomain
    #   # => "www.google.com"
    #
    #   PublicSuffixService::Domain.new("com", "google", "www").trd
    #   # => "www"
    #
    # @return [String]
    #
    # @see #subdomain?
    # @see #domain
    #
    def subdomain
      return unless subdomain?
      [trd, sld, tld].join(".")
    end

    # Returns the rule matching this domain
    # in the default {PublicSuffixService::RuleList}.
    #
    # @return [PublicSuffixService::Rule::Base, nil]
    #   The rule instance a rule matches current domain,
    #   nil if no rule is found.
    def rule
      RuleList.default.find(name)
    end


    # Checks whether <tt>self</tt> looks like a domain.
    #
    # This method doesn't actually validate the domain.
    # It only checks whether the instance contains
    # a value for the {#tld} and {#sld} attributes.
    # If you also want to validate the domain,
    # use {#valid_domain?} instead.
    #
    # @return [Boolean]
    #
    # @example
    #
    #   PublicSuffixService::Domain.new("com").domain?
    #   # => false
    #
    #   PublicSuffixService::Domain.new("com", "google").domain?
    #   # => true
    #
    #   PublicSuffixService::Domain.new("com", "google", "www").domain?
    #   # => true
    #
    #   # This is an invalid domain, but returns true
    #   # because this method doesn't validate the content.
    #   PublicSuffixService::Domain.new("zip", "google").domain?
    #   # => true
    #
    # @see #subdomain?
    #
    def domain?
      !(tld.nil? || sld.nil?)
    end

    # Checks whether <tt>self</tt> looks like a subdomain.
    #
    # This method doesn't actually validate the subdomain.
    # It only checks whether the instance contains
    # a value for the {#tld}, {#sld} and {#trd} attributes.
    # If you also want to validate the domain,
    # use {#valid_subdomain?} instead.
    #
    # @return [Boolean]
    #
    # @example
    #
    #   PublicSuffixService::Domain.new("com").subdomain?
    #   # => false
    #
    #   PublicSuffixService::Domain.new("com", "google").subdomain?
    #   # => false
    #
    #   PublicSuffixService::Domain.new("com", "google", "www").subdomain?
    #   # => true
    #
    #   # This is an invalid domain, but returns true
    #   # because this method doesn't validate the content.
    #   PublicSuffixService::Domain.new("zip", "google", "www").subdomain?
    #   # => true
    #
    # @see #domain?
    #
    def subdomain?
      !(tld.nil? || sld.nil? || trd.nil?)
    end

    # Checks whether <tt>self</tt> is exclusively a domain,
    # and not a subdomain.
    #
    # @return [Boolean]
    def is_a_domain?
      domain? && !subdomain?
    end

    # Checks whether <tt>self</tt> is exclusively a subdomain.
    #
    # @return [Boolean]
    def is_a_subdomain?
      subdomain?
    end

    # Checks whether <tt>self</tt> is valid
    # according to default {RuleList}.
    #
    # This method triggers a new rule lookup in the default {RuleList},
    # which is a quite intensive task.
    #
    # @return [Boolean]
    def valid?
      !rule.nil?
    end

    # Checks whether <tt>self</tt> looks like a domain and validates
    # according to default {RuleList}.
    #
    # @return [Boolean]
    #
    # @example
    #
    #   PublicSuffixService::Domain.new("com").domain?
    #   # => false
    #
    #   PublicSuffixService::Domain.new("com", "google").domain?
    #   # => true
    #
    #   PublicSuffixService::Domain.new("com", "google", "www").domain?
    #   # => true
    #
    #   # This is an invalid domain
    #   PublicSuffixService::Domain.new("zip", "google").false?
    #   # => true
    #
    # @see #domain?
    # @see #valid?
    #
    def valid_domain?
      domain? && valid?
    end

    # Checks whether <tt>self</tt> looks like a subdomain and validates
    # according to default {RuleList}.
    #
    # @return [Boolean]
    #
    # @example
    #
    #   PublicSuffixService::Domain.new("com").subdomain?
    #   # => false
    #
    #   PublicSuffixService::Domain.new("com", "google").subdomain?
    #   # => false
    #
    #   PublicSuffixService::Domain.new("com", "google", "www").subdomain?
    #   # => true
    #
    #   # This is an invalid domain
    #   PublicSuffixService::Domain.new("zip", "google", "www").subdomain?
    #   # => false
    #
    # @see #subdomain?
    # @see #valid?
    #
    def valid_subdomain?
      subdomain? && valid?
    end

  end

end
