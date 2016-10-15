# coding: utf-8

Encoding.default_internal = Encoding::UTF_8
Encoding.default_external = Encoding::UTF_8

require_relative 'state'

class Alice

    class ProgramError < Exception; end

    def self.run(src, debug_level=0, in_str=$stdin, out_str=$stdout, max_ticks=-1)
        new(src, debug_level, in_str, out_str, max_ticks).run
    end

    def initialize(src, debug_level=0, in_str=$stdin, out_str=$stdout, max_ticks=-1)
        @state = State.new(src, debug_level=0, in_str=$stdin, out_str=$stdout, max_ticks=-1)

        @debug_level = debug_level
    end

    def run
        ticks_exceeded = false
        loop do
            @state.print_debug_info if @debug_level > 1
            @state.mode.do_tick
            ticks_exceeded = @state.max_ticks > -1 && @state.tick >= @state.max_ticks
            break if @state.done || ticks_exceeded

            # puts "\nTick #{@tick}:" if @debug_level > 1
            # p @ip if @debug_level > 1
            # p cmd if @debug_level > 1
            # puts @main*' ' if @debug_level > 1
            # p @dir if @debug_level > 1
        end

        ticks_exceeded
    end

    private

    def process cmd
        #     cmd = cell @ip
        #     process cmd
        # opcode = :nop
        # opcode = OPERATORS[mode][cmd] if cmd >= 0 && cmd <= 1114111 # maximum Unicode code point

        # case opcode
        # # Arithmetic
        # when :push_zero
        #     push_main 0
        # when :digit
        #     val = pop_main
        #     if val < 0
        #         push_main(val*10 - param)
        #     else
        #         push_main(val*10 + param)
        #     end
        # when :inc
        #     push_main(pop_main+1)
        # when :dec
        #     push_main(pop_main-1)
        # when :add
        #     push_main(pop_main+pop_main)
        # when :sub
        #     a = pop_main
        #     b = pop_main
        #     push_main(b-a)
        # when :mul
        #     push_main(pop_main*pop_main)
        # when :div
        #     a = pop_main
        #     b = pop_main
        #     push_main(b/a)
        # when :mod
        #     a = pop_main
        #     b = pop_main
        #     push_main(b%a)
        # when :neg
        #     push_main(-pop_main)
        # when :bit_and
        #     push_main(pop_main&pop_main)
        # when :bit_or
        #     push_main(pop_main|pop_main)
        # when :bit_xor
        #     push_main(pop_main^pop_main)
        # when :bit_not
        #     push_main(~pop_main)

        # # Stack manipulation
        # when :dup
        #     push_main(peek_main)
        # when :pop
        #     pop_main
        # when :move_to_main
        #     push_main(pop_aux)
        # when :move_to_aux
        #     push_aux(pop_main)
        # when :swap_tops
        #     a = pop_aux
        #     m = pop_main
        #     push_aux m
        #     push_main a
        # when :depth
        #     push_main(@main.size)

        # # I/O
        # when :input_char
        #     byte = read_byte
        #     push_main(byte ? byte.ord : -1)
        # when :output_char
        #     @out_str.print (pop_main % 256).chr
        # when :input_int
        #     val = 0
        #     sign = 1
        #     loop do
        #         byte = read_byte
        #         case byte
        #         when '+'
        #             sign = 1
        #         when '-'
        #             sign = -1
        #         when '0'..'9', nil
        #             @next_byte = byte
        #         else
        #             next
        #         end
        #         break
        #     end

        #     loop do
        #         byte = read_byte
        #         if byte && byte[/\d/]
        #             val = val*10 + byte.to_i
        #         else
        #             @next_byte = byte
        #             break
        #         end
        #     end

        #     push_main(sign*val)
        # when :output_int
        #     @out_str.print pop_main
        # when :output_newline
        #     @out_str.puts

        # # Grid manipulation
        # when :rotate_west
        #     offset = pop_main
        #     @grid[(y+offset) % @height].rotate!(1)
            
        #     if offset == 0
        #         @ip += West.new.vec
        #         if x < 0
        #             @ip.x = @width-1
        #         end
        #     end

        #     puts @grid.map{|l| l.map{|c| OPERATORS.invert[c]}*''} if @debug_level > 1
        # when :rotate_east
        #     offset = pop_main
        #     @grid[(y+offset) % @height].rotate!(-1)
            
        #     if offset == 0
        #         @ip += East.new.vec
        #         if x >= @width
        #             @ip.x = 0
        #         end
        #     end

        #     puts @grid.map{|l| l.map{|c| OPERATORS.invert[c]}*''} if @debug_level > 1
        # when :rotate_north
        #     offset = pop_main
        #     grid = @grid.transpose
        #     grid[(x+offset) % @width].rotate!(1)
        #     @grid = grid.transpose
            
        #     if offset == 0
        #         @ip += North.new.vec
        #         if y < 0
        #             @ip.y = @height-1
        #         end
        #     end

        #     puts @grid.map{|l| l.map{|c| OPERATORS.invert[c]}*''} if @debug_level > 1
        # when :rotate_south
        #     offset = pop_main
        #     grid = @grid.transpose
        #     grid[(x+offset) % @width].rotate!(-1)
        #     @grid = grid.transpose
            
        #     if offset == 0
        #         @ip += South.new.vec
        #         if y >= @height
        #             @ip.y = 0
        #         end
        #     end

        #     puts @grid.map{|l| l.map{|c| OPERATORS.invert[c]}*''} if @debug_level > 1

        # # Others
        # when :terminate
        #     raise '[BUG] Received :terminate. This shouldn\'t happen.'
        # when :nop
        #     # Nop(e)
        # when :debug
        #     if @debug_level > 0
        #         puts
        #         puts "Grid:"
        #         puts @grid.map{|l| l.map{|c| OPERATORS.invert[c]}*''}
        #         puts "Position: #{@ip.pretty}"
        #         puts "Direction: #{@dir.class.name}"
        #         puts "Main [ #{@main*' '}  |  #{@aux.reverse*' '} ] Auxiliary"
        #     end
        # end
    end

    def error msg
        raise msg
    end
end