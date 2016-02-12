#
# Public Suffix
#
# Domain name parser based on the Public Suffix List.
#
# Copyright (c) 2009-2016 Simone Carletti <weppos@weppos.net>
#

module PublicSuffix

  # A Rule is a special object which holds a single definition
  # of the Public Suffix List.
  #
  # There are 3 types of rules, each one represented by a specific
  # subclass within the +PublicSuffix::Rule+ namespace.
  #
  # To create a new Rule, use the {PublicSuffix::Rule#factory} method.
  #
  #   PublicSuffix::Rule.factory("ar")
  #   # => #<PublicSuffix::Rule::Normal>
  #
  module Rule

    # # Abstract rule class
    #
    # This represent the base class for a Rule definition
    # in the {Public Suffix List}[http://publicsuffix.org].
    #
    # This is intended to be an Abstract class
    # and you shouldn't create a direct instance. The only purpose
    # of this class is to expose a common interface
    # for all the available subclasses.
    #
    # * {PublicSuffix::Rule::Normal}
    # * {PublicSuffix::Rule::Exception}
    # * {PublicSuffix::Rule::Wildcard}
    #
    # ## Properties
    #
    # A rule is composed by 4 properties:
    #
    # name    - The name of the rule, corresponding to the rule definition
    #           in the public suffix list
    # value   - The value, a normalized version of the rule name.
    #           The normalization process depends on rule tpe.
    # type    - The rule type (:normal, :wildcard, :exception)
    # labels  - The canonicalized rule name
    #
    # Here's an example
    #
    #   PublicSuffix::Rule.factory("*.google.com")
    #   #<PublicSuffix::Rule::Wildcard:0x1015c14b0
    #       @labels=["com", "google"],
    #       @name="*.google.com",
    #       @type=:wildcard,
    #       @value="google.com"
    #   >
    #
    # ## Rule Creation
    #
    # The best way to create a new rule is passing the rule name
    # to the <tt>PublicSuffix::Rule.factory</tt> method.
    #
    #   PublicSuffix::Rule.factory("com")
    #   # => PublicSuffix::Rule::Normal
    #
    #   PublicSuffix::Rule.factory("*.com")
    #   # => PublicSuffix::Rule::Wildcard
    #
    # This method will detect the rule type and create an instance
    # from the proper rule class.
    #
    # ## Rule Usage
    #
    # A rule describes the composition of a domain name
    # and explains how to tokenize the domain name
    # into tld, sld and trd.
    #
    # To use a rule, you first need to be sure the domain you want to tokenize
    # can be handled by the current rule.
    # You can use the <tt>#match?</tt> method.
    #
    #   rule = PublicSuffix::Rule.factory("com")
    #
    #   rule.match?("google.com")
    #   # => true
    #
    #   rule.match?("google.com")
    #   # => false
    #
    # Rule order is significant. A domain can match more than one rule.
    # See the {Public Suffix Documentation}[http://publicsuffix.org/format/]
    # to learn more about rule priority.
    #
    # When you have the right rule, you can use it to tokenize the domain name.
    #
    #   rule = PublicSuffix::Rule.factory("com")
    #
    #   rule.decompose("google.com")
    #   # => ["google", "com"]
    #
    #   rule.decompose("www.google.com")
    #   # => ["www.google", "com"]
    #
    # @abstract
    #
    class Base

      attr_reader :value, :labels

      # Initializes a new rule with name and value.
      # If value is +nil+, name also becomes the value for this rule.
      #
      # @param value [String] the value of the rule
      def initialize(value)
        @value  = value.to_s
        @labels = Domain.domain_to_labels(@value)
      end

      # Checks whether this rule is equal to <tt>other</tt>.
      #
      # @param [PublicSuffix::Rule::*] other
      #   The rule to compare.
      #
      # @return [Boolean]
      #   Returns true if this rule and other are instances of the same class
      #   and has the same value, false otherwise.
      def ==(other)
         self.equal?(other) ||
        (self.class == other.class && self.value == other.value)
      end
      alias :eql? :==

      # Checks if this rule matches +domain+.
      #
      # @param [String, #to_s] domain
      #   The domain name to check.
      #
      # @return [Boolean]
      #
      # @example
      #   rule = Rule.factory("com")
      #   # #<PublicSuffix::Rule::Normal>
      #   rule.match?("example.com")
      #   # => true
      #   rule.match?("example.net")
      #   # => false
      #
      def match?(domain)
        l1 = labels
        l2 = Domain.domain_to_labels(domain)
        odiff(l1, l2).empty?
      end

      # Checks if this rule allows +domain+.
      #
      # @param [String, #to_s] domain
      #   The domain name to check.
      #
      # @return [Boolean]
      #
      # @example
      #   rule = Rule.factory("*.do")
      #   # => #<PublicSuffix::Rule::Wildcard>
      #   rule.allow?("example.do")
      #   # => false
      #   rule.allow?("www.example.do")
      #   # => true
      #
      def allow?(domain)
        !decompose(domain).last.nil?
      end

      # Gets the length of this rule for comparison.
      # The length usually matches the number of rule +parts+.
      #
      # Subclasses might actually override this method.
      #
      # @return [Integer] The number of parts.
      def length
        parts.length
      end

      #
      # @raise  [NotImplementedError]
      # @abstract
      def parts
        raise(NotImplementedError,"#{self.class}##{__method__} is not implemented")
      end

      # @param  domain [String, #to_s] The domain name to decompose.
      # @return [Array<String, nil>]
      #
      # @raise  [NotImplementedError]
      # @abstract
      def decompose(domain)
        raise(NotImplementedError,"#{self.class}##{__method__} is not implemented")
      end

      private

      def odiff(one, two)
        ii = 0
        while(ii < one.size && one[ii] == two[ii])
          ii += 1
        end
        one[ii..one.length]
      end


      # DEPRECATED

      def self.type
        # warn("deprecated")
      end

      public
      def type
        self.class.type
      end

    end

    class Normal < Base

      # Initializes a new rule from +definition+.
      #
      # @param definition [String] the rule as defined in the PSL
      def initialize(definition)
        super(definition)
      end

      # dot-split rule value and returns all rule parts
      # in the order they appear in the value.
      #
      # @return [Array<String>]
      def parts
        @parts ||= @value.split(DOT)
      end

      # Gets the original rule definition.
      #
      # @return [String] The rule definition.
      def rule
        value
      end

      # Decomposes the domain according to rule properties.
      #
      # @param  domain [String, #to_s] The domain name to decompose.
      # @return [Array<String>] The array with [trd + sld, tld].
      def decompose(domain)
        suffix = parts.join('\.')
        domain.to_s =~ /^(.*)\.(#{suffix})$/
        [$1, $2]
      end

    end

    class Wildcard < Base

      # Initializes a new rule from +definition+.
      #
      # The wildcard "*" is removed from the value, as it's common
      # for each wildcard rule.
      #
      # @param definition [String] the rule as defined in the PSL
      def initialize(definition)
        super(definition.to_s[2..-1])
      end

      # dot-split rule value and returns all rule parts
      # in the order they appear in the value.
      #
      # @return [Array<String>]
      def parts
        @parts ||= @value.split(DOT)
      end

      # Overwrites the default implementation to cope with
      # the +*+ char.
      #
      # @return [Integer] The number of parts.
      def length
        parts.length + 1 # * counts as 1
      end

      # Gets the original rule definition.
      #
      # @return [String] The rule definition.
      def rule
        value == "" ? STAR : STAR + DOT + value
      end

      # Decomposes the domain according to rule properties.
      #
      # @param  domain [String, #to_s] The domain name to decompose.
      # @return [Array<String>] The array with [trd + sld, tld].
      def decompose(domain)
        suffix = (['.*?'] + parts).join('\.')
        domain.to_s =~ /^(.*)\.(#{suffix})$/
        [$1, $2]
      end

    end

    class Exception < Base

      # Initializes a new rule from +definition+.
      #
      # The bang ! is removed from the value, as it's common
      # for each wildcard rule.
      #
      # @param definition [String] the rule as defined in the PSL
      def initialize(definition)
        super(definition.to_s[1..-1])
      end

      # dot-split rule value and returns all rule parts
      # in the order they appear in the value.
      # The leftmost label is not considered a label.
      #
      # See http://publicsuffix.org/format/:
      # If the prevailing rule is a exception rule,
      # modify it by removing the leftmost label.
      #
      # @return [Array<String>]
      def parts
        @parts ||= @value.split(DOT)[1..-1]
      end

      # Gets the original rule definition.
      #
      # @return [String] The rule definition.
      def rule
        BANG + value
      end

      # Decomposes the domain according to rule properties.
      #
      # @param  domain [String, #to_s] The domain name to decompose.
      # @return [Array<String>] The array with [trd + sld, tld].
      def decompose(domain)
        suffix = parts.join('\.')
        domain.to_s =~ /^(.*)\.(#{suffix})$/
        [$1, $2]
      end

    end


    # Takes the +name+ of the rule, detects the specific rule class
    # and creates a new instance of that class.
    # The +name+ becomes the rule +value+.
    #
    # @example Creates a Normal rule
    #   PublicSuffix::Rule.factory("ar")
    #   # => #<PublicSuffix::Rule::Normal>
    #
    # @example Creates a Wildcard rule
    #   PublicSuffix::Rule.factory("*.ar")
    #   # => #<PublicSuffix::Rule::Wildcard>
    #
    # @example Creates an Exception rule
    #   PublicSuffix::Rule.factory("!congresodelalengua3.ar")
    #   # => #<PublicSuffix::Rule::Exception>
    #
    # @param  [String] name The rule definition.
    #
    # @return [PublicSuffix::Rule::*] A rule instance.
    def self.factory(name)
      case name.to_s[0,1]
      when STAR
        Wildcard
      when BANG
        Exception
      else
        Normal
      end.new(name)
    end

    # The default rule to use if no rule match.
    #
    # The default rule is "*". From https://publicsuffix.org/list/:
    #
    # > If no rules match, the prevailing rule is "*".
    #
    # @return [PublicSuffix::Rule::Wildcard] The default rule.
    def self.default
      factory(STAR)
    end

  end

end
