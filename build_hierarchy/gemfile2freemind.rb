#--------------------------------
#  Example of input files
#--------------------------------
#  other info
#  begin_regx
#    a (version)
#      a1 (version)
#      a2 (version)
#        a21 (version)
#          a211 (version)
#      a3 (version)
#    b (version)
#      b1 (version)
#        b11 (version)
#          b111 (version)
#    c (version)
#      a21 (version)
#    a21 (version)
#    b11 (version)
#    b111 (version)
#  end_regx
#  other info2
#
#--------------------------------
#  Example of output file
#--------------------------------
#  <node id="" value="">
#    <node id="" value="">
#      <node id="" value=""/>
#      <node id="" value=""/>
#    </node>
#  </node>
#  <node id="" value="">
#    <node id="" value=""/>
#  </node>
#  <node id="" value=""/>
#  <node id="" value=""/>
#--------------------------------
class GemlockToFreemind
  #require "build_hierarchy"
  include HierarchyTreeGenerator
  @g_xml_tree = nil

  def initialize
    @gen_xml_tree = GenerateXMLTree.new()
  end

  def generate_xml(gemlock_path, freemine_path)

    # stage 1
    b_regx = /^\s{2,}specs/
    root_b_regx = e_regx = /^\s*DEPENDENCIES/
    root_e_regx = /^\s*\n$/
    v_regx=/\s*(\S*)\s*\((.*)\)\s*/
    array_hash, all_array, level_hash, root_array = build_hierarchy_levels_and_index(gemlock_path, b_regx, e_regx, v_regx, root_b_regx, root_e_regx)
#    puts array_hash
#    puts all_array
#    puts level_hash
#    puts root_array

    # stage 2
    index_hash = build_index_relationship_hash(all_array, level_hash)
#    puts index_hash

    # stage 3
    index_hash_tree = build_index_tree(index_hash, 0)
#    puts index_hash_tree

    # stage 4
    hash_list = index_hash_tree.select { |key, v| root_array.include? key }
    result = GenerateXMLTree.new.generate({0 => hash_list}, array_hash)
#    puts array_hash
#    puts root_array
#    puts hash_list
#    puts result

    # stage 5
    write2freemind freemine_path, result
  end


  def write2freemind(path, result)
    File.delete(path) if File.exist?(path)
    f = File.new(path, "w+")
    f.write '<map version="0.9.0">'
    f.write "\n"
    f.write '<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->'
    f.write "\n"
    f.write result
    f.write "\n"
    f.write '</map>'
    f.close
  end
end
