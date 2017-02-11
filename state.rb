# coding: utf-8

require_relative 'mode'
require_relative 'point2d'
require_relative 'direction'

class State
    # I'm sorry.
    attr_accessor   :debug_level, :in_str, :out_str, :max_ticks,
                    :grid, :height, :width,
                    :ip, :dir, :storage_offset,
                    :stack, :tape, :mp, :string_mode, :current_string,
                    :tick, :done,
                    :mode

    def initialize(src, debug_level=0, in_str=$stdin, out_str=$stdout, max_ticks=-1)
        @debug_level = debug_level
        @in_str = in_str
        @out_str = out_str
        @max_ticks = max_ticks

        @grid = parse(src)
        @height = @grid.size
        @width = @height == 0 ? 0 : @grid[0].size

        @ip = Point2D.new(0, 0)
        @dir = East.new
        @storage_offset = Point2D.new(0, 0) # Will be used when source modification grows the
                                            # to the West or to the North.
        @stack = []
        @tape = []
        @mp = 0
        @string_mode = false
        @current_string = []
        @return_stack = []

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
        offset.x < 0 ? 0 : line[offset.x] || 0
    end

    def on_boundary(coords=@ip)
        offset = coords + @storage_offset
        offset.x == 0 || offset.y == 0 || offset.x == @width-1 || offset.y == @height-1
    end

    def wrap
        @ip += @storage_offset
        @ip.x %= @width
        @ip.y %= @height
        @ip -= @storage_offset
    end

    def set_cardinal
        @mode = @cardinal
    end

    def set_ordinal
        @mode = @ordinal
    end

    def push val
        @stack << val
    end

    def pop
        @stack.pop
    end

    def push_return
        @return_stack.push([@ip.x, @ip.y])
    end

    def pop_return
        @return_stack.pop || [0,0]
    end

    def shift
        @stack.shift
    end

    def unshift val
        @stack.unshift val
    end

    private

    def parse(src)
        lines = src.split($/)

        grid = lines.map{|l| l.chars.map(&:ord)}

        width = [*grid.map(&:size), 1].max

        grid.each{|l| l.fill(0, l.length...width)}
    end
end