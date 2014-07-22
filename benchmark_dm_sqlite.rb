# A benchmark for testing the effect of different SQLite PRAGMA directives
# using the Ruby DataMapper ORM framework.
#
# Copyright (c) 2014 Jonas Tingeborn
# License: MIT (http://opensource.org/licenses/MIT)

require 'dm-core'
require 'dm-migrations'
require 'benchmark'

# the pragma directives to test
PRAGMAS = [ "synchronous = OFF", "temp_store = MEMORY", "journal_mode = OFF" ]

# the entity to be persisted as a row in the database
class Entity
  include DataMapper::Resource
  property :id, Serial
  property :name, String
end

# helper to create an array of all the pragma option permutations, as set or 
# not (default)
def create_permutation(pragmas)
  x = pragmas.map{ true } + pragmas.map{ false }
  x = x.permutation.to_a.uniq.map{|a| a[0...pragmas.size]}.uniq
  ret = x.map do |a|
    opts = []
    pragmas.size.times do |i|
      opts << pragmas[i] if a[i]
    end
    opts
  end
  ret.reverse
end

# [re]creates the database and table schema
def setup
  #DataMapper::Logger.new(STDOUT, :debug)
  DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/test.db")
  adapter = DataMapper::repository(:default).adapter
  yield adapter
  DataMapper.auto_migrate!
end

# the benchmark test to be run with each pragma combination
def test(n=1000)
  n.times do |i|
    s = Entity.new
    s.name = "Entity #{i}"
    s.save
  end
end

Benchmark.bm(28) do |x|
  create_permutation(PRAGMAS).each do |opts|
    setup do |adapter|
      opts.each do |opt|
        adapter.select("PRAGMA #{opt};")
      end
    end
    title = opts.map{|s| k,v = s.split("=").map{|s|s.strip}; "%s=%s" % [k[0..3],v]}.join(" ")
    title = "DEFAULT" if title.empty?
    x.report(title){ test }
  end
end
