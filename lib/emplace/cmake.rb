require 'fileutils'

module Emplace
  class CMake
    CMAKE_LISTS = 'CMakeLists.txt'

    attr_reader :path, :file

    def initialize(path = Dir.pwd, file = CMAKE_LISTS)
      @path = File.absolute_path path
      @file = file
    end

    def has_cmake_lists?
      File.exists?(cmake_lists)
    end

    def cmake_lists
      @cmake_lists ||= File.join(path, file)
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
      cmake_contents.map {|line|
        line.text.chomp
      }.join("\n") + "\n"
    end

    def save!
      FileUtils.mkdir_p path
      File.open(cmake_lists, 'w') {|f|
        f.write to_s
      }
    end

    def set_project!(name)
      acquire!('project').arguments = [name]
    end

    def apply_template!(template)
      @lines.each {|line|
        line.apply_template! template
      }
    end

    GLOBAL_STATEMENTS = %w(
      include_directories
      link_libraries
      link_directories
      enable_testing
    )

    TARGET_STATEMENTS = %w(
      add_executable
      add_library
      add_test
      target_link_libraries
    )

    def merge!(project)
      project.statements.each {|other|
        case other.name
        when 'project'
          set_project! other.arguments.first
        when *GLOBAL_STATEMENTS
          if mine = find(other.name) 
            other.arguments.each {|arg| mine.arguments << arg}
          else
            @lines << other
          end 
        when *TARGET_STATEMENTS
          if mine = find(other.name, other.arguments.first) 
            target,*args = other.arguments
            args.each {|arg| mine.arguments << arg}
          else
            @lines << other
          end 
        end
      }
    end

    def library(name)
      Target.new('add_library', name, self)
    end

    def parse_cmake_file!(io)
      @lines = []
      io.each_line {|line| append_line! line}
    end

    class Target
      attr_reader :type, :name, :project
      def initialize(type, name, project)
        @type, @name, @project = type, name, project
      end
      def exists?
        @project.find(type, name)
      end
      def create!
        @target ||= project.acquire!(type, name)
      end
      def sources
        SourceList.new(self)
      end
    end

    class SourceList
      attr_reader :target
      def initialize(target)
        @target = target
      end
      def <<(file)
        t = target.create!
        t.arguments << file
      end
    end

    class ArgumentList < Array
      def initialize(statement)
        @statement = statement
      end
      def <<(arg)
        super
        @statement.update_arguments(self)
        self
      end
      def apply_template!(template)
        each {|arg|
          template.each {|key,val|
            arg.gsub! "%#{key}%", val
          }
        }
      end
    end

    class Whitespace
      attr_reader :text
      def initialize(text)
        @text = text
      end
      def apply_template!(template)
        template.each {|key,val|
          text.gsub! "%#{key}%", val
        }
      end
      def done?
        true
      end
    end

    class Statement
      attr_reader :text, :name, :arguments
      def initialize(text)
        @text = text
        @arguments = ArgumentList.new(self)
        if /^\w+$/.match(text.chomp)
          @name = text.chomp
        elsif m = /^\s*(\w+)\s*\(([^)]*)\)?/.match(text)
          @name = m[1]
          split_args m[2]
        end
      end
      def apply_template!(template)
        template.each {|key,val|
          text.gsub! "%#{key}%", val
        }
        arguments.apply_template!(template)
      end
      def arguments=(arguments)
        @arguments.clear
        @arguments.concat arguments
        update_arguments arguments
      end
      def update_arguments(args)
        if /\(.*\)/m.match(text)
          text.sub!(/(\([\s\r\n]*).*?([\s\r\n]*\))/, "\\1#{args.join(' ')}\\2")
        else
          @text += "(#{args.join(' ')})"
        end
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
        @arguments.concat text.split(/\s(?=(?:[^"]|"[^"]*")*$)|[\r\n]/).select {|a| ! a.empty?}
      end
    end

    def get_name(name)
      if s = find(name)
        s.arguments.first
      end
    end

    def find_all(name, arg = nil)
      exp = by_name = ->(s) { s.name.downcase == name.downcase }
      exp = ->(s) { by_name[s] && s.arguments.first == arg } if arg

      statements.find_all(&exp)
    end

    def find(name, arg = nil)
      find_all(name, arg).first
    end

    def acquire!(name, arg = nil)
      s = find(name, arg)
      unless s
        s = Statement.new(name)
        s.arguments << arg if arg
        (@lines ||= []) << s
      end
      s
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
