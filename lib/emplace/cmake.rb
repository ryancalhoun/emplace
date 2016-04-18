require 'fileutils'

module Emplace
  class CMake
    CMAKE_LISTS = 'CMakeLists.txt'

    attr_reader :path

    def initialize(path = Dir.pwd, name: nil)
      @path = File.absolute_path path

      set_project_name! name if name
    end

    def has_cmake_lists?
      File.exists?(cmake_lists)
    end

    def cmake_lists
      @cmake_lists ||= File.join(@path, CMAKE_LISTS)
    end

    def cmake_contents
      @lines || read_cmake_file{|f| parse_cmake_file! f}
      @lines || []
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

    def find_root
      cmake = self
      until cmake.is_root?
        parent = File.dirname(cmake.path)
        raise 'cannot find root of cmake project' if cmake.path == parent
        cmake = CMake.new parent
      end
      cmake
    end

    def statements
      cmake_contents.select {|line| line.is_a? Statement}
    end

    def to_s
      cmake_contents.map(&:text).join
    end

    def save!
      FileUtils.mkdir_p path
      File.open(cmake_lists, 'w') {|f|
        f.write to_s
      }
    end

    def set_project_name!(name)
      project = find('project')
      unless project
        project = Statement.new('project')
        statements << project
      end
      project.arguments = [name]
    end

    def parse_cmake_file!(io)
      @lines = []
      io.each_line {|line| append_line! line}
    end

    class Whitespace
      attr_reader :text
      def initialize(text)
        @text = text
      end
      def done?
        true
      end
    end

    class Statement
      attr_reader :text, :name, :arguments
      def initialize(text)
        @text = text
        @arguments = []
        if /^\w+$/.match(text)
          @name = text
        elsif m = /^\s*(\w+)\s*\(([^)]*)\)?/.match(text)
          @name = m[1]
          split_args m[2]
        end
      end
      def arguments=(arguments)
        @arguments = arguments
        text.sub!(/(\([\W]+).*([\W]+\))/m, "\\1#{arguments.join(' ')}\\2")
      end
      def done?
        !! /\)\s*$/m.match(text)
      end
      def <<(line)
        @text += line
        if m = /([^)]*)\)?/.match(line)
          split_args m[1]
        end
      end
      def split_args(text)
        @arguments += text.split(/\s(?=(?:[^"]|"[^"]*")*$)|[\r\n]/).select {|a| ! a.empty?}
      end
    end

    def get_name(name)
      if s = find(name)
        s.arguments.first
      end
    end

    def find(name)
      statements.find {|s| s.name == name}
    end

    def find_all(name)
      statements.find_all {|s| s.name == name}
    end

    private
    def read_cmake_file(&block)
      begin
        File.open(cmake_lists, 'r', &block) 
      rescue Errno::ENOENT
      end
    end

    def append_line!(line)
      if @lines.last && ! @lines.last.done?
        @lines.last << line
      elsif /^\s*(#.*)?$/.match(line)
        @lines << Whitespace.new(line)
      else
        @lines << Statement.new(line)
      end
    end
  end
end

