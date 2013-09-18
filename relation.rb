#
# = relation.rb
#
# == Christian Koch [cfkoch@sdf.lonestar.org]
#

require 'matrix'
require 'set'

#
# The Relation class provides an object-oriented interface for binary
# mathematical relations. A relation is any subset of the Cartesian product
# of two sets.
#
# TODO is it necessary for a relation to be between two nonempty sets?
#
class Relation
  attr_reader :set_a, :set_b, :map

  include Enumerable

  def initialize(set_a=Set[], set_b=nil, map=Set[])
    assert_set(set_a, map)
    @set_a = set_a
    @map = map

    if set_b
      assert_set(set_b)
      @set_b = set_b
    else
      @set_b = @set_a
    end
  end

  # Yields all of the mappings in this relation. Included for compatability
  # with the +Enumerable+ module.
  def each
    @map.each { |pair| yield pair }
  end

  # Assigns the first set of this relation (the "domain," to speak) to the
  # set +a+. Raises +TypeError+ if +a+ is not a Set.
  def set_a=(a)
    assert_set(a)
    @set_a = a
  end

  # Assigns the second set of this relation (the "codomain," to speak) to
  # the set +b+. Raises +TypeError+ if +b+ is not a Set.
  def set_b=(b)
    assert_set(b)
    @set_b = b
  end

  # Sets the mapping from +set_a+ to +set_b+. A mapping is a set of ordered
  # pairs, which in this case is an Array with exactly 2 elements. Raises
  # +TypeError+ if +map+ is not a Set or if any of the elements in +map+ are
  # not Arrays. Raises +ArgumentError+ if +map+ doesn't actually represent a
  # subset of the cartesian product of +set_a+ and +set_b+.
  def map=(map)
    assert_set(map)
    assert_is_relation(map)
    raise TypeError if !map.all? { |e| e.is_a?(Array) }
    raise ArgumentError if !map.all? { |e| e.length == 2 }
    @map = map
    return @map
  end

  # Adds the ordered pair <tt>[a, b]</tt> to this relation. Raises
  # +ArgumentError+ if +a+ and/or +b+ don't belong in thier respective sets.
  def map!(a, b)
    raise ArgumentError if !@set_a.include?(a) or !@set_b.include?(b)
    @map << [a, b]
  end

  # Returns +self+ as a zero-one matrix.
  def to_matrix
    Matrix.build(@set_a.length, @set_b.length) do |row, col|
      if @map.include?([@set_a.sort[row], @set_b.sort[col]])
        1
      else
        0
      end
    end
  end

  # XXX TODO Does nothing for now.
  #
  # Returns the composition of +self+ with the other relation +other+. The
  # +set_b+ attribute of +self+ must equal the +set_a+ attribute of +other+,
  # if not, +ArgumentError+ is raised. Furthermore, we raise +TypeError+ if
  # +other+ is not a Relation.
  def compose(other)
    raise NotImplementedError
    raise TypeError if !other.is_a?(Relation)
    raise ArgumentError if (@set_b != other.set_a)
  end

  # A relation is a function if each element in _A_ maps to exactly zero or
  # exactly one element in _B_.
  def function?
    all_a = @map.collect { |pair| pair.first }
    return all_a == all_a.uniq
  end

  def onto?
    return function? && (@map.collect { |pair| pair.last }.to_set == @set_b)
  end
  alias :surjective? :onto?
  alias :surjection? :onto?

  def one_to_one?
    all_b = @map.collect { |pair| pair.last }
    return function? && (all_b == all_b.uniq)
  end
  alias :injective? :one_to_one?
  alias :injection? :one_to_one?

  def one_to_one_correspondence?
    return onto? && one_to_one?
  end
  alias :bijective? :one_to_one_correspondence?
  alias :bijection? :one_to_one_correspondence?

  # A relation _R_ on a set _A_ is reflexive if for all _a_ in _A_, (_a_,
  # _a_) can be found in _R_.
  def reflexive?
    assert_on_one_set
    return reflexive_closure.subset?(@map)
  end

  # A relation _R_ on a set _A_ is irreflexive if (_a_, _a_) does NOT appear
  # in _R_ for all _a_ in _A_.
  def irreflexive?
    assert_on_one_set
    x = @map.detect { |pair| pair.first == pair.last }
    return x ? false : true
  end

  # A relation _R_ is symmetric if for all (_a_, _b_) present in _R_, the
  # pair (_b_, _a_) is also present in _R_.
  def symmetric?
    assert_on_one_set
    ab_pairs = @map.dup
    ba_pairs = ab_pairs.collect { |pair| [pair.last, pair.first] }.to_set
    return ab_pairs == ba_pairs
  end

  # XXX FIXME Make sure this implementation is correct.
  #
  # A relation _R_ is antisymmetric if for all (_a_, _b_) in _R_ where _a_
  # != _b_, the pair (_b_, _a_) is NOT in _R_.
  def antisymmetric?
    assert_on_one_set
    ab_pairs = @map.dup
    ba_pairs = ab_pairs.collect { |pair| [pair.last, pair.first] }.to_set
    return (ab_pairs.intersection(ba_pairs) - reflexive_closure).empty?
  end

  # A relation is asymmetric if (_a_, _b_) in _R_ implies that (_b_, _a_) is
  # NOT in _R_.
  def asymmetric?
    assert_on_one_set
    ab_pairs = @map.dup
    ba_pairs = ab_pairs.collect { |pair| [pair.last, pair.first] }.to_set
    return ab_pairs.intersection(ba_pairs).empty?
  end

  # A relation _R_ is transitive if (_a_, _b_) AND (_b_, _c_) in _R_ implies
  # that (_a_, _c_) is also in _R_.
  def transitive?
    assert_on_one_set

    phail = @map.detect { |ab_pair|
      potential_bc_pairs = @map.select { |pair| ab_pair.last == pair.first }
      !potential_bc_pairs.all? { |bc| @map.include? [ab_pair.first, bc.last] }
    }

    return phail ? false : true
  end

  def reflexive_closure
    assert_on_one_set
    closure = Set[]
    @set_a.each { |e| closure << [e, e] }
    return closure
  end

  def symmetric_closure
    assert_on_one_set
    ab_pairs = @map.dup
    ba_pairs = Set[]
    ab_pairs.each { |pair| ba_pairs << [pair.last, pair.first] }
    return (ba_pairs - ab_pairs)
  end

  # XXX FIXME DOES NOTHING. Although this _will_ be an implementation of
  # Warshall's algorithm.
  def transitive_closure
    raise NotImplementedError
  end

  # A relation is an equivalence relation if it is reflexive, symmetric and
  # transitive.
  def equivalence_relation?
    assert_on_one_set
    return reflexive? && symmetric? && transitive?
  end

  # A relation is a partial order if it is reflexive, antisymmetric and
  # transitive.
  def partial_order?
    assert_on_one_set
    return reflexive? && antisymmetric? && transitive?
  end

  private

  # Returns the Cartesian product of the two sets.
  def cartesian
    product = Set[]
    @set_a.each { |a|
      @set_b.each { |b|
        product << [a, b]
      }
    }
    return product
  end

  # Raises +ArgumentError+ if the given +map+ doesn't actually represent a
  # subset of the Cartesian product of the two sets.
  def assert_is_relation(map)
    raise ArgumentError if !map.subset?(cartesian)
  end

  # Raises +TypeError+ if any of the +args+ is not a Set.
  def assert_set(*args)
    raise TypeError if !args.all? { |arg| arg.is_a?(Set) }
  end

  # Raises +TypeError+ if set A and set B are not equal, i.e., if this
  # relation is not on just one set.
  def assert_on_one_set
    raise TypeError if (!@set_a == @set_b)
  end
end
