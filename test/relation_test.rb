#
# = relation_test.rb
#
# == Christian Koch [cfkoch@sdf.lonestar.org]
#

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..")
require 'relation'
require 'bacon'

describe Relation do
  before do
    @set_a = Set[:a, :b, :c, :d]
    @set_b = Set[1, 2, 3, 4]
    @r = Relation.new(@set_a, @set_b)
    @t = Relation.new(@set_b)
  end

  it "complains if given an inappropriate mapping" do
    proc { @r.map(Set[:foo, :quux]) }.should.raise ArgumentError
  end

  it "handles functions" do
    @r.map = Set[[:a, 1], [:b, 1]]
    @r.should.be.a.function
    
    @r.map = Set[[:a, 1], [:a, 2]]
    @r.should.not.be.a.function
  end

  it "handles injection" do
    @r.set_a = Set[:a, :b, :c]
    @r.map = Set[[:a, 3], [:b, 4], [:c, 1]]
    @r.should.be.one_to_one
    @r.should.not.be.onto
  end

  it "handles surjection" do
    @r.set_b = Set[1, 2, 3]
    @r.map = Set[[:a, 2], [:b, 1], [:c, 3], [:d, 2]]
    @r.should.be.onto
    @r.should.not.be.one_to_one
  end

  it "handles bijection" do
    @r.map = Set[[:a, 4], [:b, 1], [:c, 3], [:d, 2]]
    @r.should.be.onto
    @r.should.be.one_to_one
    @r.should.be.a.bijection
  end

  it "knows if it's reflexive" do
    @r.map = Set[[:a, 1]]
    @r.should.not.be.reflexive

    @t.map = Set[[1, 1], [2, 2]]
    @t.should.not.be.reflexive

    @t.map = Set[[1, 1], [2, 2], [3, 3], [4, 4], [1, 2]]
    @t.should.be.reflexive
  end

  it "knows if it's irreflexive" do
    @t.map = Set[[1, 1], [1, 2]]
    @t.should.not.be.irreflexive

    @t.map = Set[[1, 2]]
    @t.should.be.irreflexive
  end

  it "knows if it's symmetric" do
    @t.map = Set[[1, 1], [3, 3], [2, 3], [3, 2]]
    @t.should.be.symmetric

    @t.map = Set[[1, 1], [2, 4], [4, 3]]
    @t.should.not.be.symmetric
  end

  it "knows if it's antisymmetric/asymmetric" do
    # Antisymmetric but not asymmetric
    @t.map = Set[[1, 1], [3, 2], [2, 4]]
    @t.should.be.antisymmetric
    @t.should.not.be.asymmetric

    # TODO Asymmetric but not antisymmetric? I don't think that's
    # possible...

    # Neither antisymmetric nor asymmetric
    @t.map = Set[[1, 1], [3, 2], [2, 3]]
    @t.should.not.be.antisymmetric
    @t.should.not.be.asymmetric

    # Both antisymmetric and asymmetric
    @t.map = Set[[2, 3], [3, 4]]
    @t.should.be.antisymmetric
    @t.should.be.asymmetric
  end

  it "knows if it's transitive" do
    @t.map = Set[[1, 2], [2, 3], [1, 3]]
    @t.should.be.transitive

    @t.map = Set[[1, 2], [2, 3], [1, 3], [1, 4]]
    @t.should.be.transitive

    @t.map = Set[[1, 2], [2, 3], [1, 3], [2, 4]]
    @t.should.not.be.transitive
  end

  it "knows if it's an equivalence relation" do
    @t.map = Set[[1, 1], [1, 3], [2, 2], [3, 1], [3, 3], [4, 4]]
    @t.should.be.an.equivalence_relation
  end

  it "knows if it's a partial order" do
    @t.map = Set[[1, 1], [1, 2], [2, 2], [3, 3], [4, 4]]
    @t.should.be.a.partial_order
  end

  # I.e., the union of a relation R and its reflexive closure is reflexive.
  it "has a working reflexive closure" do
    @t.map = Set[[1, 2]]
    @u = Relation.new(@set_b)
    @u.map = @t.map.union(@t.reflexive_closure)
    @u.should.be.reflexive
  end

  # I.e., the union of a relation R and its symmetric closure is symmetric.
  it "has a working symmetric closure" do
    @t.map = Set[[1, 1], [3, 2]]
    @u = Relation.new(@set_b)
    @u.map = @t.map.union(@t.symmetric_closure)
    @u.map.should.equal Set[[1, 1], [3, 2], [2, 3]]
    @u.should.be.symmetric
  end

  it "properly makes matrices" do
    @r.map = Set[[:a, 1], [:a, 2], [:a, 3], [:a, 4]]
    @r.to_matrix.should.equal(
      Matrix[
        [1,1,1,1],
        [0,0,0,0],
        [0,0,0,0],
        [0,0,0,0],
      ]
    )
  end
end
