require 'json'

FILENAME = 'graph.json'

BAD_STRINGS = [
  "[",
  "]",
]

BAD_WORDS = [
  "S",
  "N",
  "SHAK",
]

# if !File.exist?(FILENAME)
#   require 'net/http'
#   require 'uri'

#   text = Net::HTTP.get(URI.parse('https://github.com/adambom/dictionary/raw/master/graph.json')) ;1
  
# end

json = File.read(FILENAME)
# graph is hash of word to array of words
dict = JSON.parse(json)

if false
  word_counts = Hash.new(0)
  word_occurrences = Hash.new {|h, k| h[k] = []}

  graph.each do |word, definition_words|
    definition_words.each do |definition_word|
      next if BAD_WORDS.include?(definition_word)
      next if BAD_STRINGS.any? {|string| definition_word.include?(string)}
      word_counts[definition_word] += 1
      word_occurrences[definition_word] << word
    end
  end

  ordered = word_counts.to_a.sort_by {|_word, count| -count}
  ordered.take(50).each {|word, count| puts "#{count.to_s.ljust(8)} #{word.inspect}"}

  BAD_WORDS.each do |word|
    puts '---------------------------'
    
    occurrences = word_occurrences[word]
    occurrences = occurrences.take(5)

    occurrences.each do |occurrence|
      puts "  #{word}:"
      puts occurrence
      puts graph[occurrence].join(' ').downcase
      puts ''
    end
    
  end
end



WORDS = %w(
  small
).map(&:upcase)

require 'set'

class Node
  attr_accessor :val
  attr_accessor :defn
  attr_accessor :succs
  attr_accessor :cache

  def initialize(val, defn)
    self.val = val
    self.defn = defn
    self.succs = Set.new
  end

  def add_succ(node)
    self.succs << node
  end

  def deps(level=0)
    # all words which must be understood to understand self.val
    # TODO this seems broken, based on deps of word "cat"
    words = Set.new
    begin
      succs.each do |node|
        # puts "adding dep #{node.val}"
        if words.include?(node.val)
          puts "  (already exists)"
          next
        else
          puts " adding its deps (#{node.defn})"
          words << (node.val)
          words.merge(node.deps(level + 1))
        end
      end
    rescue Exception => e
      puts words.size
      raise e
    end
    
    words
  end

  def print_tree(level=0)
    indent = " " * level
    puts "#{indent}#{val}"
    if level >= 2
      puts "#{indent} Reached maximum level!"
      return
    end
    succs.each {|node| node.print_tree(level + 1)}
  end
end

class Graph < Node
  attr_accessor :cache

  def initialize
    # Node with val=nil is a root
    super(nil, nil)
    self.cache = Hash.new
  end
  
  def node(val, defn)
    if n = cache[val]
      return n
    else
      n = Node.new(val, defn)
      cache[val] = n
      return n
    end
  end

  def vertices
    vs = Set.new
    cache.each do |_val, node|
      node.succs.each do |succ_node|
        vs << [node.val, succ_node.val]
      end
    end
    vs
  end

  def cycles
    # TODO find all cycles, normalized by smallest alphabetical
    # start word.
  end

  def axioms
    # TODO get all cycles, then find minimal set of words such that
    # at least one word is present in all cycles
  end

  def self.build(dict, limit=dict)
    graph = Graph.new
    limit.each do |root_word, words|
      root_node = graph.node(root_word, words.join(" "))
      graph.succs << root_node
      words.each do |word|
        # skip words in definitions that aren't in the dictionary
        next if !dict.key?(word)
        
        node = graph.node(word)
        root_node.add_succ node
      end
    end
    graph
  end
end

limit = {}
# Would be easier if I just had Hash#slice
WORDS.each {|key| limit[key] = dict[key]}

graph = Graph.build(dict, dict)
puts dict.size
p ['nodes', graph.cache.size]
p ['vertices', graph.vertices.size]

graph.cache.each do |val, node|
  
end

WORDS.each do |word|
  node = graph.node(word)
  puts node.val
  p node.deps.to_a
  puts ""
end

while true
  word = gets.strip.upcase
  p word
  puts dict[word].join(" ")
end
