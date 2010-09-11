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

  class Rule

    # Takes the <tt>name</tt> of the rule, detects the specific rule class
    # and creates a new instance of that class.
    # The <tt>name</tt> becomes the rule value.
    #
    # name - The rule String definition
    #
    # Examples
    #
    #   PublicSuffixService::Rule.factory("ar")
    #   # => #<PublicSuffixService::Rule::Normal>
    #
    #   PublicSuffixService::Rule.factory("*.ar")
    #   # => #<PublicSuffixService::Rule::Wildcard>
    #
    #   PublicSuffixService::Rule.factory("!congresodelalengua3.ar")
    #   # => #<PublicSuffixService::Rule::Exception>
    #
    def self.factory(name)
      klass = case name.to_s[0..0]
        when "*"  then  "wildcard"
        when "!"  then  "exception"
        else            "normal"
      end
      const_get(klass.capitalize).new(name)
    end


    #
    # = Abstract rule class
    #
    # This represent the base class for a Rule definition
    # in the {Public Suffix List}[http://publicsuffix.org].
    # 
    # This is intended to be an Abstract class
    # and you sholnd't create a direct instance. The only purpose
    # of this class is to expose a common interface
    # for all the available subclasses.
    #
    # * PublicSuffixService::Rule::Normal
    # * PublicSuffixService::Rule::Exception
    # * PublicSuffixService::Rule::Wildcard
    #
    # == Properties
    #
    # A rule is composed by 4 properties:
    #
    # name    - The name of the rule, corresponding to the rule definition
    #           in the public suffic list
    # value   - The value, a normalized version of the rule name.
    #           The normalization process depends on rule tpe.
    # type    - The rule type (:normal, :wildcard, :exception)
    # labels  - The canonicalized rule name
    #
    # Here's an example
    #
    #   PublicSuffixService::Rule.factory("*.google.com")
    #   #<PublicSuffixService::Rule::Wildcard:0x1015c14b0 
    #       @labels=["com", "google"],
    #       @name="*.google.com",
    #       @type=:wildcard,
    #       @value="google.com"
    #   >
    #
    # == Rule Creation
    #
    # The best way to create a new rule is passing the rule name
    # to the <tt>PublicSuffixService::Rule.factory</tt> method.
    #
    #   PublicSuffixService::Rule.factory("com")
    #   # => PublicSuffixService::Rule::Normal
    #
    #   PublicSuffixService::Rule.factory("*.com")
    #   # => PublicSuffixService::Rule::Wildcard
    #
    # This method will detect the rule type and create an instance
    # from the proper rule class.
    #
    # == Rule Usage
    #
    # A rule describes the composition of a domain name
    # and explains how to tokenize the domain name
    # into tld, sld and trd.
    #
    # To use a rule, you first need to be sure the domain you want to tokenize
    # can be handled by the current rule.
    # You can use the <tt>#match?</tt> method.
    #
    #   rule = PublicSuffixService::Rule.factory("com")
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
    #   rule = PublicSuffixService::Rule.factory("com")
    # 
    #   rule.decompose("google.com")
    #   # => ["google", "com"]
    # 
    #   rule.decompose("www.google.com")
    #   # => ["www.google", "com"]
    #
    class Base

      attr_reader :name, :value, :type, :labels

      # Initializes a new rule with name and value.
      # If value is nil, name also becomes the value for this rule.
      def initialize(name, value = nil)
        @name   = name.to_s
        @value  = value || @name
        @type   = self.class.name.split("::").last.downcase.to_sym
        @labels = Domain.domain_to_labels(@value)
      end

      # Checks whether this rule is equal to <tt>other</tt>.
      #
      # other - An other PublicSuffixService::Rule::Base to compare.
      #
      # Returns true if this rule and other are instances of the same class
      # and has the same value, false otherwise.
      def ==(other)
        return false unless other.is_a?(self.class)
        self.equal?(other) ||
        self.name == other.name
      end
      alias :eql? :==


      # Checks whether this rule matches <tt>domain</tt>.
      #
      # domain - A string with the domain name to check.
      #
      # Returns a true if this rule matches domain,
      # false otherwise.
      def match?(domain)
        l1 = labels
        l2 = Domain.domain_to_labels(domain)
        odiff(l1, l2).empty?
      end

      # Gets the length of this rule for comparison.
      # The length usually matches the number of rule <tt>parts</tt>.
      # Subclasses might actually override this method.
      #
      # Returns an Integer with the number of parts.
      def length
        parts.length
      end

      # Raises NotImplementedError.
      def parts
        raise NotImplementedError
      end

      # Raises NotImplementedError.
      def decompose(domain)
        raise NotImplementedError
      end


      private


        def odiff(one, two)
          ii = 0
          while(ii < one.size && one[ii] == two[ii])
            ii += 1
          end
          one[ii..one.length]
        end

    end

    class Normal < Base

      def initialize(name)
        super(name, name)
      end

      # dot-split rule value and returns all rule parts
      # in the order they appear in the value.
      #
      # Returns an Array with the domain parts.
      def parts
        @parts ||= @value.split(".")
      end

      # Decomposes the domain according to rule properties.
      #
      # domain - A String with the domain name to parse
      #
      # Return an Array with [trd + sld, tld].
      def decompose(domain)
        domain.to_s =~ /^(.*)\.(#{parts.join('\.')})$/
        [$1, $2]
      end

    end

    class Wildcard < Base

      def initialize(name)
        super(name, name.to_s[2..-1])
      end

      # dot-split rule value and returns all rule parts
      # in the order they appear in the value.
      #
      # Returns an Array with the domain parts.
      def parts
        @parts ||= @value.split(".")
      end

      def length
        parts.length + 1 # * counts as 1
      end

      # Decomposes the domain according to rule properties.
      #
      # domain - A String with the domain name to parse
      #
      # Return an Array with [trd + sld, tld].
      def decompose(domain)
        domain.to_s =~ /^(.*)\.(.*?\.#{parts.join('\.')})$/
        [$1, $2]
      end

    end

    class Exception < Base

      def initialize(name)
        super(name, name.to_s[1..-1])
      end

      # dot-split rule value and returns all rule parts
      # in the order they appear in the value.
      # The leftmost label is not considered a label.
      #
      # See http://publicsuffix.org/format/:
      # If the prevailing rule is a exception rule,
      # modify it by removing the leftmost label. 
      #
      # Returns an Array with the domain parts.
      def parts
        @parts ||= @value.split(".")[1..-1]
      end

      # Decomposes the domain according to rule properties.
      #
      # domain - A String with the domain name to parse
      #
      # Return an Array with [trd + sld, tld].
      def decompose(domain)
        domain.to_s =~ /^(.*)\.(#{parts.join('\.')})$/
        [$1, $2]
      end

    end

  end

end
