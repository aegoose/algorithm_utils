module HierarchyTreeGenerator
  # calculate the number of space with a string
  def cal_space str
    fst = str[0]
    return 0 unless fst.eql?(" ")
    i = 0
    str.chars.to_a.each do |s|
      return i unless s.eql?(" ")
      i += 1
    end
    i
  end

  # Build 3 data structure from the file
  #
  # @param[filename] file with hierarchy format line
  #   file:
  #   ------------------------------------
  #     begin string
  #       value1 (extend value)
  #         value11 (extend value)
  #       value2 (extend value)
  #       value3 (extend value)
  #         value31 (extend value)
  #           value2 (extend value)
  #       ...
  #     end string
  #     root begin string
  #       value1 (extend value)
  #       value2 (extend value)
  #     root end string
  #   ------------------------------------
  # @param[begin_regx] pattern of the line begin
  # @param[end_regx] pattern of the line end
  # @param[value_regx] pattern to read the values of line
  # @param[root_begin_regx]
  # @param[root_end_regx]
  # @param[init_space]
  #
  # @return [Array, Array, Hash, Array]
  # item_hash = [
  #   {:value => v1, :ext_value => v2},
  #   ... ...
  #   {:value => v1, :ext_value => v2}
  # ]
  # all_array = [
  #   {level, item_index}
  #   {level, item_index},
  #   {level, item_line}
  #   ... ...
  # ]
  # levels = {
  #    1 => [array_index, array_index, ...],
  #    2 => [[array_index, array_index, ...],
  #    ... ...
  # }
  # root_indexes = [index, index, ...]
  #
  # Example:
  #    array_hash, level_hash, depth = build_array_and_level("../Gemfile.lock", "^\s{2,}specs","^\s*DEPENDENCIES")
  def build_hierarchy_levels_and_index(filename, begin_regx, end_regx, value_regx=/\s*(\S*)\s*\((.*)\)\s*/, root_begin_regx=/^$/, root_end_regx=/^$/, init_space=1)
    filename = filename

    f = File.open(filename, "r")
    start = false # flag of building hierarchy index or not
    root_start = false # flag of building root index or not

    arr_hash = Array.new() # index array, store all values
    all_array = Array.new() # index array, store the level and index of arr_hash
    level_hash = Hash.new # level hash, store all index categorized by level

    arr_hash[0] = {:value=>"root"} # init first value
    all_array[0] = {:level => 0, :index => 0} # init first array
    root_indexes = Array.new() # init a blank roots

    index = 1 # index of all_array
    value_index = 1 # index of arr_hash

    begin_level = init_space # init the first space
    value_hash = {}

    f.each_line do |line|
      if !start && !(line =~ begin_regx).nil?
        start = true
      elsif start && !(line =~ end_regx).nil?
        start = false
      end

      if !root_start && !(line =~ root_begin_regx).nil?
        root_start = true
      elsif root_start && !(line =~ root_end_regx).nil?
        root_start = false
      end
#      puts "#{line.gsub(/\n/, "")} - #{value_regx} #{line.match(value_regx).nil?}"
      if start && !(match_line = line.match(value_regx)).nil?
        level = (cal_space line)/2 - begin_level # 2 space is a flag or hierarchy level
        value, ext_value = match_line[1..2]
        unless value.nil? or level.nil?
          if (curr_index = value_hash[value]).nil?
            # store real value
            value_hash[value] = value_index #temp hash
            arr_hash[value_index] = {:value => value, :ext_value => ext_value}
            curr_index = value_index
            value_index += 1
          end
          # store level and arr_hash index to all_array
          all_array[index] = {:level => level, :index => curr_index}
          # store level with all array index
          level_hash[level].nil? ? level_hash[level] = [index] : level_hash[level] << index
          # next
          index += 1
        end
      elsif root_start && !(match_line = line.match(value_regx)).nil?
        root_indexes << value_hash[match_line[1]]
      end
    end
    [arr_hash, all_array, level_hash, root_indexes]
  end

  # Build a index relationship hash, every index link with children indexes
  # @param[index_array]
  #   [
  #     {:level => level, item_index => index},
  #     {:level => level, item_index => index},
  #     {:level => level, item_index => index}
  #     ... ...
  #   ]
  # @param[level_hash]
  #   {
  #     1 => [array_index, array_index, ...],
  #     2 => [[array_index, array_index, ...],
  #     ... ...
  #   }
  # @return[Hash]
  #   {
  #     0 => [index, index, index]
  #     1 => [index, index]
  #     2 => ""
  #     3 => [index]
  #     4 => ""
  #     5 => ""
  #     ...
  #   }
  def build_index_relationship_hash(index_array, level_hash)
    levels = level_hash
    arr = index_array
    hash = Hash.new

    hash[0] = levels[1].collect { |x| arr[x][:index] }.uniq # the root

    levels.each do |l_key, l_arr|
      x = l_arr[0]
      next_node = 1
      while !x.nil?
        if arr[x+1].nil?
          # x is the end leaf
          hash[x] = ""
          break
        end

        x_index = arr[x][:index]

        if arr[x+1][:level] <= arr[x][:level]
          # x is a leaf, store it and next
          hash[x_index] = "" if hash[x_index].nil?
        else
          # x hash children
          # levels[l_key+1] is the next level
          y = l_arr[next_node] || (arr.length-1) # get rand of children (x ~ y)
          levels[l_key + 1].each do |l|
            # only store the index in x ~ y
            if l > x && l < y
              l_index = arr[l][:index]
              hash[x_index].nil? ? hash[x_index]=[l_index] : hash[x_index] << l_index
            end
          end
        end
        x = l_arr[next_node]
        next_node += 1
      end
    end
    hash
  end

  # Build a hash hierarchy tree
  #
  # @param[index_hash]
  #   {
  #     0 => [index, index, index]
  #     1 => [index, index]
  #     2 => ""
  #     3 => [index]
  #     4 => ""
  #     5 => ""
  #     ...
  #   }
  # @param[root] a root index, from the index_hash
  # @return[Hash]
  #   tree_hash = {
  #     0 => {
  #       1 => {
  #         4 => nil,
  #         5 => nil
  #       },
  #       2 => nil,
  #       3 => {
  #         6 => nil,
  #         7 => nil,
  #       }
  #     }
  #   }
  #   like:
  #         0
  #        /|\
  #       1 2 3
  #      /|   |\
  #     4 5   6 7
  def build_index_tree(index_hash, root)
    hash = index_hash
    children = hash[root]
    # return a tree hash, have a top parent, is root
    tree = {root=>{}}
    # visit root's children
    children.each do |index|
      if hash[index].eql?("")
        # the child is a leaf, just return nil
        tree[root][index] = nil
      else
        # the child a sub-tree, return the tree
        tree[root][index]= build_index_tree(index_hash, index)
      end
    end
    # return a hold tree
    tree[root]
  end

  class GenerateHashTree

    def initialize
      @i = 1000
      @prefix1 = "#{rand(1000000)+6123456}"
      @prefix0 = "#{rand(10000000)+13123523}"
    end

    def generate(hash_tree, value_array)

    end

    def next_seq()
      @i += 1
      @prefix0.to_s + @i.to_s
    end

    def next_id()
      @i += 1
      @prefix1.to_s + @i.to_s
    end

  end

  class GenerateXMLTree < GenerateHashTree
    def initialize
      super()
    end

    def generate(hash_tree, value_array)
      hash = hash_tree
      arr = value_array
      seq = next_seq
      id = next_id
      if hash.is_a?(Hash)
        return hash.collect do |k, v|
          if v.nil?
            "<node CREATED='#{seq}' ID='ID_#{id}' MODIFIED='' TEXT='#{arr[k][:value]}'/>"
          elsif not arr[k].nil?
            "<node CREATED='#{seq}' ID='ID_#{id}' MODIFIED='' TEXT='#{arr[k][:value]}'>#{generate(v, value_array)}</node>"
          end
        end.join("\n")
      end
      ""
    end
  end

end