# coding: utf-8

Encoding.default_internal = Encoding::UTF_8
Encoding.default_external = Encoding::UTF_8

require_relative 'state'

# Add stable sorting methods to Enumerable
module Enumerable
  def stable_sort
    sort_by.with_index { |x, idx| [x, idx] }
  end

  def stable_sort_by
    sort_by.with_index { |x, idx| [yield(x), idx] }
  end
end

# Add convenience method for .chr(Encoding::UTF_8)
class Integer
    def chr_utf_8
        chr(Encoding::UTF_8)
    end
end

class Alice
    attr_accessor :state

    class ProgramError < Exception; end


    def self.run(src, in_str=$stdin, out_str=$stdout, args=ARGV, max_ticks=-1)
        new(src, in_str, out_str, args, max_ticks).run
    end

    def initialize(src, in_str=$stdin, out_str=$stdout, args=ARGV, max_ticks=-1)
        @state = State.new(src, in_str, out_str, args, max_ticks)
    end

    def run
        ticks_exceeded = false

        loop do
            next while !@state.mode.move

            cell = @state.cell
            processed = false
            if @state.string_mode
                case cell
                when "'".ord
                    @state.mode.raw_move
                    @state.current_string << @state.cell
                    @state.ip -= @state.dir.vec
                    processed = true
                when '"'.ord
                    @state.string_mode = false
                else
                    @state.current_string << cell
                    processed = true
                end
            elsif cell == '"'.ord
                @state.string_mode = true
                @state.current_string = []
                processed = true
            end

            if !processed
                iterator = @state.get_iterator
                case iterator
                when Integer
                    iterator.times { @state.mode.process cell.chr_utf_8 }
                when String
                    iterator.each_char do |c|
                        @state.push c
                        @state.mode.process cell.chr_utf_8
                    end
                end
            end

            @state.tick += 1
            ticks_exceeded = @state.max_ticks > -1 && @state.tick >= @state.max_ticks
            break if @state.done || ticks_exceeded
        end

        ticks_exceeded
    end

    private

    def error msg
        raise msg
    end
end
