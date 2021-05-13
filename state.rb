# coding: utf-8

require_relative 'mode'
require_relative 'point2d'
require_relative 'direction'

class State
    # I'm sorry.
    attr_accessor   :in_str, :out_str, :args, :max_ticks,
                    :grid, :height, :width,
                    :ip, :dir, :storage_offset,
                    :stack, :tape, :rp, :mp, :string_mode, :current_string, 
                    :tick, :done,
                    :mode

    def initialize(src, in_str=$stdin, out_str=$stdout, args=ARGV, max_ticks=-1)
        @in_str = in_str
        @out_str = out_str
        @out_str.binmode # Put the output stream in binary mode so that
                         # we can write non-UTF-8 bytes.
        @args = args

        @max_ticks = max_ticks

        @grid = parse(src)
        @height = @grid.size
        @width = @height == 0 ? 0 : @grid[0].size

        @ip = Point2D.new(-1, 0) # Instruction pointer
        @dir = East.new
        @storage_offset = Point2D.new(0, 0) # Will be used when source modification grows the
                                            # to the West or to the North.
        @stack = []
        @tape = Hash.new(-1)
        @mp = 0 # Memory pointer
        @rp = 0 # Register pointer
        @string_mode = false
        @current_string = []
        @return_stack = []
        @iterator_queue = []

        @tick = 0
        @done = false

        @cardinal = Cardinal.new(self)
        @ordinal = Ordinal.new(self)

        set_cardinal
    end 

    def x
        @ip.x
    end

    def y
        @ip.y
    end

    def jump x, y
        @ip.x = x
        @ip.y = y
    end

    def cell(coords=@ip)
        offset = coords + @storage_offset
        line = offset.y < 0 ? [] : @grid[offset.y] || []
        offset.x < 0 ? -1 : line[offset.x] || -1
    end

    def put_cell(coords, value)
        offset = coords + @storage_offset

        # Grow grid if necessary
        if offset.x >= @width
            @width = offset.x+1
            @grid.each{|l| l.fill(-1, l.length...@width)}
        end

        if offset.x < 0
            @width -= offset.x
            @storage_offset.x -= offset.x
            @grid.map{|l| l.unshift(*[-1]*(-offset.x))}
            offset.x = 0
        end

        if offset.y >= @height
            @height = offset.y+1
            while @grid.size < height
                @grid << [-1]*@width
            end
        end

        if offset.y < 0
            @height -= offset.y
            @storage_offset.y -= offset.y
            while @grid.size < height
                @grid.unshift([-1]*@width)
            end
            offset.y = 0
        end

        @grid[offset.y][offset.x] = value

        # Shrink the grid if possible
        if value == 0 && on_boundary(coords)
            while @height > 0 && @grid[0]-[-1] == []
                @grid.shift
                @height -= 1
            end

            while @height > 0 && @grid[-1]-[-1] == []
                @grid.pop
                @height -= 1
            end

            while @width > 0 && @grid.transpose[0]-[-1] == []
                @grid.map(&:shift)
                @width -= 1
            end

            while @width > 0 && @grid.transpose[-1]-[-1] == []
                @grid.map(&:pop)
                @width -= 1
            end
        end
    end

    def min_x
        -@storage_offset.x
    end

    def min_y
        -@storage_offset.y
    end

    def max_x
        @width - @storage_offset.x - 1
    end

    def max_y
        @height - @storage_offset.y - 1
    end

    def on_boundary(coords=@ip)
        coords.x == min_x || coords.y == min_y || coords.x == max_x || coords.y == max_y
    end

    def wrap
        @ip += @storage_offset
        case @dir
        when East
            @ip.x = 0 if @ip.x >= @width
        when West
            @ip.x = @width-1 if @ip.x < 0
        when South
            @ip.y = 0 if @ip.y >= @height
        when North
            @ip.y = @height-1 if @ip.y < 0
        end
        @ip -= @storage_offset
    end

    def set_cardinal
        @mode = @cardinal
        @other_mode = @ordinal
    end

    def set_ordinal
        @mode = @ordinal
        @other_mode = @cardinal
    end

    def toggle_mode
        @mode, @other_mode = @other_mode, @mode
    end

    def push val
        @stack << val
    end

    def pop
        @stack.pop
    end

    def push_return(coords=@ip)
        @return_stack.push([coords.x, coords.y])
    end

    def pop_return
        @return_stack.pop || [@ip.x, @ip.y]
    end

    def peek_return
        @return_stack[-1] || [@ip.x, @ip.y]
    end

    def get_iterator
        @iterator_queue.shift || 1
    end

    def add_iterator iter
        @iterator_queue << iter
    end

    def skip_next
        @iterator_queue.unshift(0)
    end

    def read_register
        chars = []
        i = @rp
        while is_char?(@tape[i])
            chars << @tape[i]
            i += 1
        end
        chars.map(&:chr_utf_8).join
    end

    def print_debug_info
        $stderr.puts "Mode: #{@mode.class}"
        print_grid
        print_iterators
        print_stack
        print_tape
        print_register
        print_args
        print_tick
    end

    def print_grid
        $stderr.puts 'Grid:'
        $stderr.puts ' '*(@ip.x+@storage_offset.x)+'v'
        @grid.each_with_index do |line, i|
            line.each {|c| $stderr << (is_char?(c) && (c == 10 || c >= 32) ? c : 32).chr_utf_8}
            $stderr << ' <' if i == @ip.y + @storage_offset.y
            $stderr.puts
        end
        $stderr.puts
        $stderr.puts "Top left coordinate: #{(@storage_offset*-1).pretty}"
        $stderr.puts "IP: #{@ip.pretty}"
        $stderr.puts "Direction: #{@dir.class}"
        $stderr.puts "Return address stack: ... (0,0)#{@return_stack.map{|p|' ('+p[0].to_s+','+p[1].to_s+')'}.join}"
        $stderr.puts
    end

    def print_iterators
        $stderr.puts 'Iterators:'
        $stderr.puts "<< #{@iterator_queue.empty? ? '(1)' : @iterator_queue.map(&:inspect).join(' ')} <<"
        $stderr.puts
    end

    def print_tape
        $stderr.puts 'Tape:'
        min, max = [@mp, @rp, *@tape.keys].minmax
        width = 0
        rp_str = "OTH:"
        tape_str = " ..."
        mp_str = "CTH:"
        (min-1 .. max+1).map do |i|
            s = @tape[i].to_s
            tape_str << ' ' << s
            rp_str << ' ' << (i == @rp ? 'v'*s.size + " (#{i})" : ' '*s.size)
            mp_str << ' ' << (i == @mp ? '^'*s.size + " (#{i})" : ' '*s.size)
        end
        tape_str << ' ...'
        $stderr.puts rp_str
        $stderr.puts tape_str
        $stderr.puts mp_str
        $stderr.puts
    end

    def print_stack
        $stderr.puts 'Stack:'
        $stderr.puts "[...#{@stack.map{|e|' '+e.inspect}.join}]"
        $stderr.puts
    end

    def print_register
        $stderr.puts 'Register:'
        $stderr.puts read_register
        $stderr.puts
    end

    def print_args
        $stderr.puts 'Remaining arguments:'
        $stderr.puts @args.inspect
        $stderr.puts
    end

    def print_tick
        $stderr.puts "Tick: #{@tick}"
        $stderr.puts
    end

    private

    def is_char? val
        val && (val >= 0 && val <= 0xD7FF || val >= 0xE000 && val <= 0x10FFFF)
    end

    def parse(src)
        lines = src.split($/, -1)

        grid = lines.map{|l| l.chars.map(&:ord)}

        width = [*grid.map(&:size), 1].max

        grid.each{|l| l.fill(32, l.length...width)}
    end
end
