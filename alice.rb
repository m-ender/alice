# coding: utf-8

Encoding.default_internal = Encoding::UTF_8
Encoding.default_external = Encoding::UTF_8

require_relative 'state'

class Alice

    class ProgramError < Exception; end

    def self.run(src, in_str=$stdin, out_str=$stdout, max_ticks=-1)
        new(src, in_str, out_str, max_ticks).run
    end

    def initialize(src, in_str=$stdin, out_str=$stdout, max_ticks=-1)
        @state = State.new(src, in_str, out_str, max_ticks)
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
                    iterator.times { @state.mode.process cell.chr }
                when String
                    iterator.each_char do |c|
                        @state.push c
                        @state.mode.process cell.chr
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