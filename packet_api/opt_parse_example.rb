require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'

class OptparseExample
  Version = '1.0.0'

  CODES = %w[iso-2022-jp shift_jis euc-jp utf8 binary]
  CODE_ALIASES = { "jis" => "iso-2022-jp", "sjis" => "shift_jis" }

  class ScriptOptions
    attr_accessor :library, :inplace, :encoding, :transfer_type,
                  :verbose, :extension, :delay, :time, :record_separator,
                  :list

    def initialize
      self.library = []
      self.inplace = false
      self.encoding = "utf8"
      self.transfer_type = :auto
      self.verbose = false
    end

    def define_options(parser)
      parser.banner = "Usage: example.rb [options]"
      parser.separator ""
      parser.separator "Specific options:"

      # add additional options
      perform_inplace_option(parser)
      delay_execution_option(parser)
      execute_at_time_option(parser)
      specify_record_separator_option(parser)
      list_example_option(parser)
      specify_encoding_option(parser)
      optional_option_argument_with_keyword_completion_option(parser)
      boolean_verbose_option(parser)

      parser.separator ""
      parser.separator "Common options:"
      # No argument, shows at tail.  This will print an options summary.
      # Try it and see!
      parser.on_tail("-h", "--help", "Show this message") do
        puts parser
        exit
      end
      # Another typical switch to print the version.
      parser.on_tail("--version", "Show version") do
        puts Version
        exit
      end
    end

    def perform_inplace_option(parser)
      # Specifies an optional option argument
      parser.on("-i", "--inplace [EXTENSION]",
                "Edit ARGV files in place",
                "(make backup if EXTENSION supplied)") do |ext|
        self.inplace = true
        self.extension = ext || ''
        self.extension.sub!(/\A\.?(?=.)/, ".")  # Ensure extension begins with dot.
      end
    end

    def delay_execution_option(parser)
      # Cast 'delay' argument to a Float.
      parser.on("--delay N", Float, "Delay N seconds before executing") do |n|
        self.delay = n
      end
    end

    def execute_at_time_option(parser)
      # Cast 'time' argument to a Time object.
      parser.on("-t", "--time [TIME]", Time, "Begin execution at given time") do |time|
        self.time = time
      end
    end

    def specify_record_separator_option(parser)
      # Cast to octal integer.
      parser.on("-F", "--irs [OCTAL]", OptionParser::OctalInteger,
                "Specify record separator (default \\0)") do |rs|
        self.record_separator = rs
      end
    end

    def list_example_option(parser)
      # List of arguments.
      parser.on("--list x,y,z", Array, "Example 'list' of arguments") do |list|
        self.list = list
      end
    end

    def specify_encoding_option(parser)
      # Keyword completion.  We are specifying a specific set of arguments (CODES
      # and CODE_ALIASES - notice the latter is a Hash), and the user may provide
      # the shortest unambiguous text.
      code_list = (CODE_ALIASES.keys + CODES).join(', ')
      parser.on("--code CODE", CODES, CODE_ALIASES, "Select encoding",
                "(#{code_list})") do |encoding|
        self.encoding = encoding
      end
    end

    def optional_option_argument_with_keyword_completion_option(parser)
      # Optional '--type' option argument with keyword completion.
      parser.on("--type [TYPE]", [:text, :binary, :auto],
                "Select transfer type (text, binary, auto)") do |t|
        self.transfer_type = t
      end
    end

    def boolean_verbose_option(parser)
      # Boolean switch.
      parser.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        self.verbose = v
      end
    end
  end

  #
  # Return a structure describing the options.
  #
  def parse(args)
    # The options specified on the command line will be collected in
    # *options*.

    @options = ScriptOptions.new
    @args = OptionParser.new do |parser|
      @options.define_options(parser)
      parser.parse!(args)
    end
    @options
  end

  attr_reader :parser, :options
end  # class OptparseExample

example = OptparseExample.new
options = example.parse(ARGV)
pp options # example.options
pp ARGV
