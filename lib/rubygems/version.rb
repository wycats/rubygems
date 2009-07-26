#--
# Copyright 2006 by Chad Fowler, Rich Kilmer, Jim Weirich and others.
# All rights reserved.
# See LICENSE.txt for permissions.
#++

##
# The Version class processes string versions into comparable
# values. A version string should normally be a series of numbers
# separated by periods. Each part (digits separated by periods) is
# considered its own number, and these are used for sorting. So for
# instance, 3.10 sorts higher than 3.2 because ten is greater than
# two.
#
# If any part contains letters (currently only a-z are supported) then
# that version is considered prerelease. Versions with a prerelease
# part in the Nth part sort less than versions with N-1 parts. Prerelease
# parts are sorted alphabetically using the normal Ruby string sorting
# rules.
#
# Prereleases sort between real releases (newest to oldest):
#
# 1. 1.0
# 2. 1.0.b
# 3. 1.0.a
# 4. 0.9

class Gem::Version

  include Comparable

  VERSION_PATTERN = '[0-9]+(\.[0-9a-z]+)*'
  PATTERN = /\A\s*(#{VERSION_PATTERN})*\s*\z/

  attr_reader :version

  ##
  # Factory method to create a Version object.  Input may be a Version or a
  # String.  Intended to simplify client code.
  #
  #   ver1 = Version.create('1.3.17')   # -> (Version object)
  #   ver2 = Version.create(ver1)       # -> (ver1)
  #   ver3 = Version.create(nil)        # -> nil

  def self.create(input)
    if input.respond_to? :version then
      input
    elsif input.nil? then
      nil
    else
      new input
    end
  end

  ##
  # Constructs a Version from the +version+ string.  A version string is a
  # series of digits or ASCII letters separated by dots.

  def initialize(version)
    unless version.is_a?(Array) || version.is_a?(Integer) || version.to_s =~ PATTERN
      raise ArgumentError, "Malformed version number string #{version}"
    end

    @rel_parts, @prerelease = [], false

    if version.is_a?(Array)
      self.parts = version
    else
      version = version.to_s
      version.strip!
      @version = version
    end
  end

  def inspect # :nodoc:
    "#<#{self.class} #{version.inspect}>"
  end

  ##
  # Strip ignored trailing zeros.

  def normalized_parts
    @normalized_parts ||= begin
      new_parts = parts.dup
      new_parts.pop while new_parts.last == 0
      new_parts.push(0) if new_parts.empty?
      new_parts
    end
  end

  def parts_for(parts)
    parts.map! do |whole|
      begin
        part = Integer(whole)
        @rel_parts << part unless @prerelease
        part
      rescue ArgumentError
        @prerelease = true
        whole
      end
    end
  end

  def parts # :nodoc:
    @parts ||= parts_for(@version.to_s.scan(/[0-9a-z]+/i))
  end

  def parts=(parts)
    @parts = parts_for(parts)
  end

  def marshal_load(parts)
    if parts.size == 1 && parts[0].is_a?(String)
      initialize(parts[0])
    else
      initialize(parts)
    end
  end

  alias normalize normalized_parts
  alias marshal_dump parts

  ##
  # Returns the text representation of the version

  def to_s
    version
  end

  def to_yaml_properties
    version && ["@version"]
  end

  def version
    @version ||= parts.join(".")
  end

  ##
  # A version is considered a prerelease if any part contains a letter.

  def prerelease?
    parts && @prerelease
  end

  ##
  # The release for this version (e.g. 1.2.0.a -> 1.2.0)
  # Non-prerelease versions return themselves
  def release
    prerelease? ? self.class.new(@rel_parts) : self
  end

  def yaml_initialize(tag, values)
    initialize(values["version"])
  end

  ##
  # Compares this version with +other+ returning -1, 0, or 1 if the other
  # version is larger, the same, or smaller than this one.

  def <=>(other)
    return nil unless self.class === other
    return 1 unless other

    mine, theirs = balance(self.parts.dup, other.parts.dup)

    mine.each_with_index do |part, i|
      other_part = theirs[i]

      if part.is_a?(Numeric) && other_part.is_a?(String)
        return 1
      elsif part.is_a?(String) && other_part.is_a?(Numeric)
        return -1
      elsif part != other_part
        return part <=> other_part
      end
    end
    return 0
  end

  def balance(a, b)
    [a.fill(0, a.size, b.size - a.size), b.fill(0, b.size, a.size - b.size)]
  end

  ##
  # A Version is only eql? to another version if it has the same version
  # string.  "1.0" is not the same version as "1".

  def eql?(other)
    other.is_a?(self.class) and parts == other.parts
  end

  def hash # :nodoc:
    parts.hash
  end

  ##
  # Return a new version object where the next to the last revision number is
  # one greater. (e.g.  5.3.1 => 5.4)
  #
  # Pre-release (alpha) parts are ignored. (e.g 5.3.1.b2 => 5.4)

  def bump
    new_parts = parts.dup
    new_parts.pop while new_parts.last.is_a?(String)
    new_parts.pop if new_parts.size > 1

    new_parts.push new_parts.pop.succ

    self.class.new(new_parts)
  end

  def pretty_print(q) # :nodoc:
    q.text "Gem::Version.new(#{@version.inspect})"
  end

  #:stopdoc:

  require 'rubygems/requirement'

  ##
  # Gem::Requirement's original definition is nested in Version.
  # Although an inappropriate place, current gems specs reference the nested
  # class name explicitly.  To remain compatible with old software loading
  # gemspecs, we leave a copy of original definition in Version, but define an
  # alias Gem::Requirement for use everywhere else.

  Requirement = ::Gem::Requirement

  # :startdoc:

end

