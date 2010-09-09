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

  module Version
    MAJOR = 0
    MINOR = 4
    PATCH = 0
    BUILD = nil

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join(".")
  end

  VERSION = Version::STRING

end
