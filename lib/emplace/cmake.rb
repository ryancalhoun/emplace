module Emplace
  class CMake
    CMAKE_LISTS = 'CMakeLists.txt'

    def initialize(path = Dir.pwd)
      @path = path
    end

    def has_cmake_lists?
      File.exists?(cmake_lists)
    end

    def cmake_lists
      @cmake_lists ||= File.join(@path, CMAKE_LISTS)
    end

    def cmake_contents
      @cmake_contents ||= File.open(cmake_lists, 'r') {|f| f.read}
    end

    def project_name
      @project_name ||= get_name('project')
    end

    def library_name
      @libary_name ||= get_name('add_library')
    end

    def executable_name
      @executable_name ||= get_name('add_executable')
    end

    def is_root?
      !! project_name && ! library_name && ! executable_name
    end

    private
    def get_name(type)
      if m = /\b#{type}\s*\(\s*(\w+)/.match(cmake_contents)
        m[1]
      end
    end
  end
end

require 'byebug'
