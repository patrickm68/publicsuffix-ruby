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


class DomainName

  # = Rule List
  #
  # A DomainName::RuleList is a collection of one or more DomainName::Rule.
  #
  # Given a RuleList, you can add or remove DomainName::Rule,
  # iterate all items in the list or search for the first rule
  # which matches a specific domain name.
  #
  #   # Create a new list
  #   list =  DomainName::RuleList.new
  #
  #   # Push two rules to the list
  #   list << DomainName::Rule.factory("it")
  #   list << DomainName::Rule.factory("com")
  #
  #   # Get the size of the list
  #   list.size
  #   # => 2
  #
  #   # Search for the rule matching given domain
  #   list.find("example.com")
  #   # => #<DomainName::Rule::Normal>
  #   list.find("example.org")
  #   # => nil
  #
  # You can create as many DomainName::RuleList you want.
  # The DomainName::RuleList.default rule list is used by DomainName
  # to tokenize and validate a domain.
  #
  # DomainName::RuleList implements Enumerable module.
  #
  class RuleList
    include Enumerable

    # Gets the list of rules.
    # Each rule is expected to be a subclass of DomainName::Rule::Base.
    #
    # Returns an Array of rules.
    attr_reader :list


    # Initializes an empty DomainName::RuleList.
    # If block is given, yields on self.
    def initialize(&block) # :yields: self
      @list = []
      yield(self) if block_given?
    end

    # Checks whether two lists are equal.
    # RuleList <tt>one</tt> is equal to <tt>two</tt>, if <tt>two</tt> is an instance of 
    # <tt>DomainName::RuleList</tt> and each <tt>DomainName::Rule::Base</tt>
    # in list <tt>one</tt> is available in list <tt>two</tt>,
    # in the same order.
    #
    # other - The DomainName::RuleList to compare.
    #
    # Returns true if self is equal to other.
    def ==(other)
      return false unless other.is_a?(RuleList)
      self.equal?(other) ||
      self.list == other.list
    end
    alias :eql? :==

    # Iterates each rule in the list.
    #
    # Returns nothing.
    def each(*args, &block)
      @list.each(*args, &block)
    end

    # Gets the list as Array.
    #
    # Return an Array.
    def to_a
      @list
    end

    # Adds the given object to the list.
    #
    # rule - The rule to add to the list. 
    #        Expected to be a subclass of DomainName::Rule::Base.
    #
    # Returns self.
    def add(rule)
      @list << rule
      self
    end
    alias << add

    # Gets the number of elements in the list.
    #
    # Returns an Integer.
    def size
      @list.size
    end
    alias length size

    # Checks whether the list is empty.
    #
    # Returns true if the list contains no elements.
    def empty?
      @list.empty?
    end

    # Removes all elements.
    #
    # Returns self.
    def clear
      @list.clear
      self
    end


    # Returns the most appropriate rule for domain.
    #
    # From the Public Suffix List documentation:
    #
    # * If a hostname matches more than one rule in the file,
    #   the longest matching rule (the one with the most levels) will be used.
    # * An exclamation mark (!) at the start of a rule marks an exception to a previous wildcard rule.
    #   An exception rule takes priority over any other matching rule.
    #
    # == Algorithm description
    #
    # * Match domain against all rules and take note of the matching ones.
    # * If no rules match, the prevailing rule is "*".
    # * If more than one rule matches, the prevailing rule is the one which is an exception rule.
    # * If there is no matching exception rule, the prevailing rule is the one with the most labels.
    # * If the prevailing rule is a exception rule, modify it by removing the leftmost label.
    # * The public suffix is the set of labels from the domain
    #   which directly match the labels of the prevailing rule (joined by dots).
    # * The registered domain is the public suffix plus one additional label.
    #
    # Note: This might not be the most efficient algorithm.
    #
    # Returns a DomainName::Rule::Base instance or nil.
    def find(domain)
      rules = select(domain)
      rules.select { |r|   r.type == :exception }.first ||
      rules.inject { |t,r| t.length > r.length ? t : r }
    end

    # Selects all the rules matching given domain.
    #
    # Returns an Array of rules.
    #   Each rule is expected to be a subclass of DomainName::Rule::Base.
    def select(domain)
      @list.select { |rule| rule.match?(domain) }
    end


    @@default = nil

    class << self

      # Gets the default <tt>DomainName::RuleList</tt>.
      # Initializes a new <tt>DomainName::RuleList</tt> 
      # parsing the content of <tt>DomainName::RuleList.default_definition</tt> if necessary.
      #
      # Returns an instance of DomainName::RuleList.
      def default
        @@default ||= parse(default_definition)
      end

      # Sets the default <tt>DomainName::RuleList</tt> to <tt>value</tt>.
      #
      # value - The new DomainName::RuleList.
      #
      # Returns the new DomainName::RuleList.
      def default=(value)
        @@default = value
      end

      # Sets the default <tt>DomainName::RuleList</tt> to <tt>nil</tt>.
      #
      # Returns self.
      def clear
        self.default = nil
        self
      end

      # Resets the default <tt>DomainName::RuleList</tt> and reinitialize it
      # parsing the content of <tt>DomainName::RuleList.default_definition</tt>.
      #
      # Returns an instance of DomainName::RuleList.
      def reload
        self.clear.default
      end

      # Gets the default definition list.
      # Can be any <tt>IOStream</tt> including a <tt>File</tt> or a simple <tt>String</tt>.
      # The object must respond to <tt>#each_line</tt>.
      #
      # Returns an object which responds to <tt>#each_line</tt>.
      def default_definition
        File.new(File.join(File.dirname(__FILE__), "definitions.dat"))
      end


      # Parse given <tt>input</tt> treating the content as Public Suffic List.
      # See http://publicsuffix.org/format/ for more details about input format.
      #
      # Returns an Array of DomainName::Rule::Base.
      def parse(input)
        new do |list|
          input.each_line do |line|
            line.strip!

            # strip blank lines
            if line.empty?
              next
            # strip comments
            elsif line =~ %r{^//}
              next
            # append rule
            else
              list << Rule.factory(line)
            end
          end
        end
      end

    end

  end

end