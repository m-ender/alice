# coding: utf-8

require_relative 'point2d'
require_relative 'direction'

require 'prime'
require 'date'

class Mode
    # List of operators which should not be ignored while in string mode.
    STRING_CMDS = "\"'\\/_|"

    def initialize(state)
        @state = state
    end

    def is_char? val
        val && val >= 0 && val <= 1114111
    end

    def process
        raise NotImplementedError
    end

    def process_string
        raise NotImplementedError
    end

    # Returns true when the resulting cell is a command.
    def move
        raw_move if @state.cell == "'".ord
        raw_move

        cell = @state.cell 
        case cell
        when '/'.ord, '\\'.ord
            @state.dir = @state.dir.reflect cell.chr
            @state.toggle_mode
            return false
        when '_'.ord, '|'.ord
            @state.dir = @state.dir.reflect cell.chr
            return false
        end

        return true if @state.string_mode

        @state.print_debug_info if cell == '`'.ord

        is_char?(cell) && self.class::OPERATORS.has_key?(cell.chr)
    end

    # Moves the IP a single cell without regard for mirrors, walls or no-ops.
    # Does respect grid boundaries.
    def raw_move
        raise NotImplementedError
    end

    def push val
        @state.push val
    end

    def pop
        raise NotImplementedError
    end

    def push_return
        @state.push_return
    end

    def pop_return
        @state.pop_return
    end

    def peek
        val = pop
        push val
        val
    end
end

class Cardinal < Mode
    OPERATORS = {
        '@'  => :terminate,
        
        '<'  => :move_west,
        '>'  => :move_east,
        '^'  => :move_north,
        'v'  => :move_south,

        '{'  => :turn_left,
        '}'  => :turn_right,
        
        '#'  => :trampoline,
        '$'  => :cond_trampoline,
        '='  => :cond_sign,
        '&'  => :repeat_iterator,

        '~'  => :swap,
        '.'  => :dup,
        ';'  => :discard,
        ','  => :rotate_stack,

        '0'  => :digit, '1'  => :digit, '2'  => :digit, '3'  => :digit, '4'  => :digit, '5'  => :digit, '6'  => :digit, '7'  => :digit, '8'  => :digit, '9'  => :digit,
        '+'  => :add,
        '-'  => :sub,
        '*'  => :mul,
        ':'  => :div,
        '%'  => :mod,

        '!'  => :store_tape,
        '?'  => :load_tape,
        '['  => :mp_left,
        ']'  => :mp_right,
        '('  => :search_left,
        ')'  => :search_right,
        
        '"'  => :leave_string_mode,
        "'"  => :escape,

        'I'  => :input,
        'O'  => :output,
        'i'  => :raw_input,
        'o'  => :raw_output,

        'A'  => :bitand,
        'C'  => :binomial,
        'D'  => :deduplicate,
        'E'  => :power,
        'F'  => :divides,
        'G'  => :gcd,
        'H'  => :abs,
        'J'  => :jump_raw,
        'K'  => :return_raw,
        'L'  => :lcm,
        'M'  => :divmod,
        'N'  => :bitnot,
        'P'  => :factorial,
        'Q'  => :convert,
        'R'  => :negate,
        'S'  => :replace_divisors,
        'T'  => :sleep,
        'V'  => :bitor,
        'W'  => :discard_return,
        'X'  => :bitxor,
        'Y'  => :unpack,
        'Z'  => :pack,

        'a'  => :const_10,
        'b'  => :random,
        'c'  => :prime_factors,
        'd'  => :stack_depth,
        'e'  => :const_m1,
        'f'  => :prime_factor_pairs,
        'g'  => :get_cell,
        'h'  => :inc,
        'j'  => :jump,
        'k'  => :return,
        'l'  => :clear_bits,
        'm'  => :floor,
        'n'  => :not,
        'p'  => :put_cell,
        'q'  => :get_mp,
        'r'  => :range,
        's'  => :sortswap,
        't'  => :dec,
        'u'  => :set_bits,
        'w'  => :push_return,
        'x'  => :extract_bit,
        'y'  => :bit_if,
        'z'  => :transpose_ip,
    }

    OPERATORS.default = :nop

    def raw_move
        @state.ip += @state.dir.vec
        @state.wrap
    end

    def pop
        val = nil

        loop do
            val = @state.pop
            if val.is_a?(String)
                found = false
                val.scan(/(?:^|(?!\G))-?\d+/) { push $&.to_i; found = true }
                next if !found
                val = @state.pop
            end

            break
        end

        val || 0
    end

    def process cmd
        opcode = OPERATORS[cmd]

        case opcode
        when :nop
            raise "No-op reached process(). This shouldn't happen."
                
        when :terminate
            @state.done = true

        when :move_east
            @state.dir = East.new
        when :move_west
            @state.dir = West.new
        when :move_south
            @state.dir = South.new
        when :move_north
            @state.dir = North.new
        when :turn_left
            @state.dir = @state.dir.left
        when :turn_right
            @state.dir = @state.dir.right
        when :trampoline
            move
        when :cond_trampoline
            move if pop == 0
        when :cond_sign            
            val = pop
            if val < 0
                @state.dir = @state.dir.left
            elsif val > 0
                @state.dir = @state.dir.right
            end
        when :repeat_iterator
            @state.add_iterator pop
        when :transpose_ip
            @state.jump(@state.ip.y, @state.ip.x)
            case @state.dir
            when East
                @state.dir = South.new
            when West
                @state.dir = North.new
            when South
                @state.dir = East.new
            when North
                @state.dir = West.new
            end

        when :jump
            push_return
            y = pop
            x = pop
            @state.jump(x,y)
        when :return
            @state.jump(*pop_return)
        when :jump_raw
            y = pop
            x = pop
            @state.jump(x,y)
        when :return_raw
            target = pop_return
            push_return target
            @state.jump(*target)
        when :push_return
            push_return
        when :discard_return
            pop_return

        when :get_cell
            y = pop
            x = pop
            push @state.cell(Point2D.new(x,y))
        when :put_cell
            v = pop
            y = pop
            x = pop
            @state.put_cell(Point2D.new(x,y), v)

        when :store_tape
            @state.tape[@state.mp] = pop
        when :load_tape
            push (@state.tape[@state.mp] || -1)
        when :mp_left
            @state.mp -= 1
        when :mp_right
            @state.mp += 1
        when :search_left
            val = pop
            @state.mp -= 1 while @state.tape[@state.mp] != val
        when :search_right
            val = pop
            @state.mp += 1 while @state.tape[@state.mp] != val
        when :get_mp
            push @state.mp

        when :leave_string_mode
            @state.stack += @state.current_string
        when :escape
            raw_move
            push @state.cell
            @state.ip -= @state.dir.vec

        when :input
            char = @state.in_str.getc
            push(char ? char.ord : -1)
        when :output
            # Will throw an error when value isn't a valid code point
            @state.out_str << pop.chr
        when :raw_input
            push(@state.in_str.getbyte || -1)
        when :raw_output
            # TODO: do

        when :digit
            push cmd.chr.to_i
        when :add
            push(pop + pop)
        when :sub
            y = pop
            push(pop - y)
        when :mul
            push(pop * pop)
        when :div
            y = pop
            push(pop / y)
        when :mod
            y = pop
            push(pop % y)
        when :divmod
            y = pop
            x = pop
            push(x / y)
            push(x % y)
        when :inc
            push(pop+1)
        when :dec
            push(pop-1)
        when :abs
            push(pop.abs)
        when :power
            y = pop
            x = pop
            if y < 0
                push 0
            else
                push x**y
            end
        when :bitand
            push(pop & pop)
        when :bitnot
            push(~pop)
        when :bitor
            push(pop | pop)
        when :bitxor
            push(pop ^ pop)
        when :bitif
            z = pop
            y = pop
            x = pop
            push(x&y | ~x&z)
        when :clear_bits
            x = pop
            if x > 0
                msb = Math.log2(x).floor
            elsif x < -1
                msb = Math.log2(~x).floor
            else
                msb = 0
            end
            push (x & -(2**msb))
        when :set_bits
            x = pop
            if x > 0
                msb = Math.log2(x).floor
            elsif x < -1
                msb = Math.log2(~x).floor
            else
                msb = 0
            end
            push (x | (2**msb-1))
        when :extract_bit
            y = pop
            x = pop
            if y >= 0
                push x[y]
            else
                if x > 0
                    msb = Math.log2(x).floor
                elsif x < -1
                    msb = Math.log2(~x).floor
                else
                    msb = 0
                end
                push x[msb-y+1]
            end

        when :factorial
            val = pop
            if val >= 0
                push (1..val).reduce(1, :*)
            else
                push (val..-1).reduce(1, :*)
            end
        when :binomial
            k = pop
            n = pop

            k = n-k if n > 0 && k > n/2
            
            if k < 0
                push 0
            else
                prod = 1
                (1..k).each do |i|
                    prod *= n
                    prod /= i
                    n -= 1
                end
                push prod
            end
        when :negate
            push -pop
        when :prime_factors
            # TODO: settle on behaviour for n < 2
            Prime.prime_division(pop).each{ |p,n| n.times{ push p } }
        when :prime_factor_pairs
            # TODO: settle on behaviour for n < 2
            Prime.prime_division(pop).flatten.each{ |x| push x }
        when :deduplicate
            Prime.int_from_prime_division(Prime.prime_division(pop.map{ |p,n| [p,1]}))
        when :divides
            y = pop
            x = pop
            if x % y == 0
                push y
            else
                push 0
            end
        when :gcd
            push (pop.gcd pop)
        when :lcm
            push (pop.lcm pop)
        when :floor
            y = pop
            x = pop
            push (x/y)*y
        when :replace_divisors
            z = pop
            y = pop
            x = pop
            if x == 0
                push 0
            else
                order = 0
                while x%y == 0
                    order += 1 
                    x /= y
                end
                x *= z**order
            end

        when :pack
            y = pop
            x = pop

            # Map integers to naturals
            sgn = x <=> 0
            x = x*sgn*2 + [0, sgn].min

            sgn = y <=> 0
            y = y*sgn*2 + [0, sgn].min

            # Map two naturals to one
            z = (x+y)*(x+y+1)/2 + y

            # Map the natural back to an integer
            z = (-1)**z * ((z+1)/2)

            push z

        when :unpack
            z = pop

            # Map the integer to a positive natural
            sgn = z <=> 0
            z = z*sgn*2 + [0, sgn].min

            # Map the natural to two
            y = z
            x = 0
            while x < y
                x += 1
                y -= x
            end
            x -= y

            # Map the naturals back to integers
            x = (-1)**x * ((x+1)/2)
            y = (-1)**y * ((y+1)/2)

            push x
            push y

        when :not
            push (pop == 0 ? 1 : 0)

        when :range
            val = pop
            if val >= 0
                0.upto(val) {|i| push i}
            else
                (-val).downto(0) {|i| push i}
            end

        when :random
            val = pop
            if val > 0
                push rand val
            elsif val == 0
                push 0 # TODO: or something else?
            else
                push -(rand val)
            end

        when :sortswap
            top = pop
            second = pop

            top, second = second, top if top < second

            push second
            push top

        when :swap
            top = pop
            second = pop
            push top
            push second
        when :dup
            top = pop
            push top
            push top
        when :discard
            pop
        when :stack_depth
            push @state.stack.size
        when :rotate_stack
            n = pop
            if n > 0
                if n >= @state.stack.size
                    push 0
                else
                    push @state.stack[-n-1]
                    @state.stack.delete_at(-n-2)
                end
            elsif n < 0
                top = pop
                @state.stack = [0]*[-n-@state.stack.size, 0].max + @state.stack
                @state.stack.insert(n-1, top)
            end
        when :convert
            n = pop
            n.times.map{pop}.reverse.each{|v| push v}
        when :sleep
            sleep pop/1000.0
        when :const_10
            push 10
        when :const_m1
            push -1

        end
    end
end

class Ordinal < Mode
    OPERATORS = {
        '@'  => :terminate,

        '0'  => :digit, '1'  => :digit, '2'  => :digit, '3'  => :digit, '4'  => :digit, '5'  => :digit, '6'  => :digit, '7'  => :digit, '8'  => :digit, '9'  => :digit,
        '+'  => :concat,
        '-'  => :drop,
        '*'  => :riffle,
        ':'  => :occurrences,
        '%'  => :split,

        '<'  => :ensure_west,
        '>'  => :ensure_east,
        '^'  => :ensure_north,
        'v'  => :ensure_south,

        '{'  => :turn_left,
        '}'  => :turn_right,
        
        '#'  => :trampoline,
        '$'  => :cond_trampoline,
        '='  => :cond_cmp,
        '&'  => :fold_iterator,

        '~'  => :swap,
        '.'  => :dup,
        ';'  => :discard,
        ','  => :permute_stack,

        '!'  => :store_register,
        '?'  => :load_register,
        '['  => :register_left,
        ']'  => :register_right,
        '('  => :search_left,
        ')'  => :search_right,

        '"'  => :leave_string_mode,
        "'"  => :escape,

        'I'  => :input,
        'O'  => :output,
        'i'  => :raw_input,
        'o'  => :raw_output,

        'A'  => :intersection,
        'C'  => :subsequences,
        'D'  => :deduplicate,
        'E'  => :substrings,
        'F'  => :find,
        'G'  => :longest_common_substring,
        'H'  => :trim,
        'J'  => :jump_raw,
        'K'  => :return_raw,
        'L'  => :shortest_common_superstring,
        'M'  => :inclusive_split,
        'N'  => :complement,
        'P'  => :permutations,
        'Q'  => :reverse_stack,
        'R'  => :reverse,
        'S'  => :replace,
        'T'  => :datetime,
        'V'  => :union,
        'W'  => :discard_return,
        'X'  => :symdifference,
        'Y'  => :unzip,
        'Z'  => :zip,

        'a'  => :const_lf,
        'b'  => :shuffle,
        'c'  => :characters,
        'd'  => :push_joined_stack,
        'e'  => :const_empty,
        'f'  => :runs,
        'g'  => :get_diagonal,
        'h'  => :head,
        'j'  => :jump,
        'k'  => :return,
        'l'  => :lower_case,
        'm'  => :truncate_to_shorter,
        'u'  => :upper_case,
        'n'  => :not,
        'p'  => :put_diagonal,
        'q'  => :join_tape,
        'r'  => :expand_ranges,
        's'  => :sort,
        't'  => :tail,
        'w'  => :push_return,
        'x'  => :permute,
        'y'  => :transliterate,
        'z'  => :transpose,

        #'('  => ,
        #')'  => ,

        #'!'  => ,
        #'$'  => ,
        #'&'  => ,
        #','  => ,
        #'.'  => ,
        #';'  => ,
        #'='  => ,
        #'?'  => ,
        #'`'  => ,

        #'A'  => ,
        # ...
        #'Z'  => ,
        #'a'  => ,
        # ...
        #'z'  => ,
    }

    OPERATORS.default = :nop

    def raw_move
        if @state.width == 1 || @state.height == 1
            return
        end

        new_pos = @state.ip + @state.dir.vec + @state.storage_offset
        @state.dir = @state.dir.reflect('|') if new_pos.x < 0 || new_pos.x >= @state.width
        @state.dir = @state.dir.reflect('_') if new_pos.y < 0 || new_pos.y >= @state.height

        @state.ip += @state.dir.vec
    end

    def pop
        val = @state.pop

        val ? val.to_s : ''
    end

    def scan_source label
        ip_dir = @state.dir
        grid = @state.grid
        while !ip_dir.is_a? NorthEast
            grid = grid.transpose.reverse
            ip_dir = ip_dir.left
        end

        height = grid.size
        width = height == 0 ? 0 : grid[0].size

        positions = []

        (0..width+height-2).map do |d|
            min_x = [0,d-height+1].max
            max_x = [width-1,d].min
            line = (min_x..max_x).map do |x|
                y = d - x
                grid[y][x].chr
            end.join

            line.scan(/(?=#{Regexp.escape(label)})/) do
                x = min_x + $`.size + label.size - 1
                y = d-x
                positions << [x,y]
            end
        end

        ip_dir = @state.dir
        while !ip_dir.is_a? NorthEast
            ip_dir = ip_dir.left
            positions.map! {|x, y| [grid.size - y - 1, x]}
            grid = grid.reverse.transpose
        end

        positions
    end

    def process cmd
        opcode = OPERATORS[cmd]
        
        case opcode
        when :nop
            raise "No-op reached process(). This shouldn't happen."
                
        when :terminate
            @state.done = true

        when :ensure_west
            @state.dir = @state.dir.reflect '|' if @state.dir.vec.x > 0
        when :ensure_east
            @state.dir = @state.dir.reflect '|' if @state.dir.vec.x < 0
        when :ensure_north
            @state.dir = @state.dir.reflect '_' if @state.dir.vec.y > 0
        when :ensure_south
            @state.dir = @state.dir.reflect '_' if @state.dir.vec.y < 0
        when :turn_left
            @state.dir = @state.dir.left
        when :turn_right
            @state.dir = @state.dir.right
        when :trampoline
            move
        when :cond_trampoline
            move if pop == ''
        when :cond_cmp
            top = pop
            second = pop
            if top > second 
                @state.dir = @state.dir.left
            elsif top < second
                @state.dir = @state.dir.right
            end
        when :fold_iterator
            @state.add_iterator pop

        when :jump
            push_return
            label = pop
            positions = scan_source(label)
            @state.jump(*positions[0]) if !positions.empty?
        when :return
            @state.jump(*pop_return)
        when :jump_raw
            label = pop
            positions = scan_source(label)
            @state.jump(*positions[0]) if !positions.empty?
        when :return_raw
            target = pop_return
            push_return target
            @state.jump(*target)
        when :push_return
            push_return
        when :discard_return
            pop_return

        when :get_diagonal
            label = pop
            positions = scan_source(label)
            if !positions.empty?
                cursor = Point2D.new(*positions[0]) + @state.dir.vec
                string = ''
                while is_char? @state.cell(cursor)
                    string << @state.cell(cursor)
                    cursor += @state.dir.vec
                end
                push string
            end
        when :put_diagonal
            value = pop
            label = pop
            positions = scan_source(label)
            if !positions.empty?
                cursor = Point2D.new(*positions[0]) + @state.dir.vec
                value.each_char {|c|
                    @state.put_cell(cursor, c.ord)
                    cursor += @state.dir.vec
                }
            end

        when :store_register
            i = @state.rp
            pop.each_char do |c|
                @state.tape[i] = c.ord
                i += 1
            end
            @state.tape[i] = -1
        when :load_register
            push @state.read_register
        when :register_left
            @state.rp -= 1 while is_char? @state.tape[@state.rp-1]
            @state.rp -= 1
            @state.rp -= 1 while is_char? @state.tape[@state.rp-1]
        when :register_right
            @state.rp += 1 while is_char? @state.tape[@state.rp]
            @state.rp += 1
        when :search_left
            needle = pop
            last = @state.rp
            string = ""

            @state.tape.keys.select{|i| i < @state.rp}.sort.reverse.map do |i|
                if i+1 == last && is_char?(@state.tape[i])
                    string << @state.tape[i]
                elsif string.reverse[needle]
                    @state.rp = last
                    break
                else
                    string = ""
                end
                last = i
            end
        when :search_right
            needle = pop
            last = @state.rp-1
            string = ""

            @state.tape.keys.select{|i| i >= @state.rp}.sort.map do |i|
                if i-1 == last && is_char?(@state.tape[i])
                    string << @state.tape[i]
                elsif string[needle]
                    @state.rp = last - string.size + 1
                    break
                else
                    string = ""
                end
                last = i
            end
        when :join_tape
            push @state.tape.keys.sort.map{|i| @state.tape[i]}.select{|v| is_char?(v)}.map(&:chr).join

        when :leave_string_mode
            # Will throw an error when cell isn't a valid code point
            push @state.current_string.map(&:chr).join
        when :escape
            raw_move
            push @state.cell.chr # Will throw an error when cell isn't a valid code point
            @state.ip -= @state.dir.vec

        when :digit
            push(pop + cmd.chr)

        when :input
            line = @state.in_str.gets
            push(line ? line.chomp : '')
        when :output
            @state.out_str.puts pop
        when :raw_input
            push(@state.in_str.read || '')
        when :raw_output
            @state.out_str << pop

        when :concat
            top = pop
            second = pop
            push(second + top)
        when :drop
            y = pop
            x = pop
            result = x.chars
            x.scan(/(?=#{Regexp.escape(y)})/) do
                y.size.times do |i|
                    result[$`.size + i] = 0
                end
            end

            push (result-[0]).join
        when :riffle
            sep = pop
            push(pop.chars * sep)
        when :occurrences
            sep = pop
            pop.scan(/#{Regexp.escape(sep)}/){ push sep }
        when :split
            sep = pop
            @state.stack += pop.split(sep, -1)
        when :inclusive_split
            sep = pop
            str = pop
            splits = str.split(sep, -1)
            str.scan(/#{Regexp.escape(sep)}/){ push splits.shift; push sep }
            push splits.shift
        when :replace
            target = pop
            needle = pop
            haystack = pop
            push haystack.gsub(needle, target)
        when :trim
            push pop.gsub(/^[ \n\t]+|[ \n\t]+$/, '')
        when :transliterate
            target = pop
            source = pop
            string = pop
            if target.empty?
                source.each_char {|c| string.gsub!(c, '')}
            else
                target += target[-1]*[source.size-target.size,0].max
                string = string.chars.map{|c| target[source.index c]}.join
            end
            push string
        when :transpose
            lines = pop.lines
            width = lines.map(&:size).max
            (0...width).map do |i|
                lines.map{|l| l[i] || ''}.join
            end.join $/
        when :find
            needle = pop
            haystack = pop
            push(haystack[needle] || '')
        when :truncate_to_shorter
            top = pop
            second = pop
            length = [top.size, second.size].min
            push second[0,length]
            push top[0,length]
        when :zip
            top = pop.chars
            second = pop.chars
            result = []
            while !top.empty? || !second.empty?
                result << (second.shift || '')
                result << (top.shift || '')
            end
            push result * ''
        when :unzip
            str = pop
            left = ''
            right = ''
            str.scan(/(.)(.|$)/s) do
                left << $1
                right << $2
            end
            push left
            push right

        when :shortest_common_superstring
            top = pop
            second = pop
            len = [top.size, second.size].min
            len.downto(0) do |i|
                if second[-i,i] == top[0,i]
                    push second+top[i..-1]
                    break
                end
            end
        when :longest_common_substring
            top = pop
            second = pop
            second.size.downto(0) do |l|
                if l == 0
                    push ""
                else
                    shared = second.chars.each_cons(l).select {|s| top[s.join]}
                    if !shared.empty?
                        shared.uniq.each{|s| push s.join}
                        break
                    end
                end
            end            

        when :intersection
            second = pop
            first = pop
            result = first.chars.select {|c|
                test = second[c]
                second[c] = '' if test
                test
            }
            push result.join
        when :union
            second = pop
            first = pop
            first.each_char {|c| second[c] = '' if second[c]}
            push(first + second)
        when :symdifference
            second = pop
            first = pop

            temp_second = second.clone

            first.each_char {|c| second[c] = '' if second[c]}
            temp_second.each_char {|c| first[c] = '' if first[c]}

            push first+second
        when :complement
            second = pop
            first = pop
            second.each_char {|c| first[c] = '' if first[c]}

            push first

        when :deduplicate
            push pop.chars.uniq.join

        when :sort
            push pop.chars.sort.join

        when :shuffle
            push pop.chars.shuffle.join

        when :characters
            @stack.state += pop.chars
        when :runs
            pop.scan(/(.)\1*/s){push $&}
        when :head
            str = pop
            if str == ''
                push ''
                push ''
            else
                push str[0]
                push str[1..-1]
            end
        when :tail
            str = pop
            if str == ''
                push ''
                push ''
            else
                push str[0..-2]
                push str[-1]
            end

        when :lower_case
            push pop.downcase
        when :upper_case
            push pop.upcase
        when :swap_case
            push pop.swapcase

        when :not
            push(pop == '' ? 'Jabberwocky' : '')

        when :reverse
            push pop.reverse
        when :permutations
            @state.stack += pop.chars.permutation.map{|p| p.join}.to_a
        when :subsequences
            str = pop.chars
            (0..str.size).each do |l|
                str.combination(l).each {|s| push s.join}
            end
        when :substrings
            str = pop.chars
            (1..str.size).each do |l|
                str.each_cons(l).each {|s| push s.join}
            end
        when :permute
            top = pop
            second = pop
            push (0...second.size).stable_sort_by{|i| 
                c = top[i]
                c ? c.ord : 1114112 # Value greater than any code point, so that trailing
                                    # characters remain in place.
            }.map{|i| second[i]}.join

        when :expand_ranges
            val = pop
            val.chars.each_cons(2).map{ |a,b| 
                if a > b
                    (b..a).drop(1).to_a.reverse.join
                else
                    (a...b).to_a.join
                end
            }.join + (val[-1] || '')


        when :swap
            top = pop
            second = pop
            push top
            push second
        when :dup
            top = pop
            push top
            push top
        when :discard
            pop
        when :push_joined_stack
            push @state.stack.join
        when :reverse_stack
            @state.stack.reverse!.map!(:to_s)
        when :permute_stack
            top = pop
            max_size = [@state.stack.size, top.size].max
            @state.stack = (-max_size..-1).stable_sort_by{|i| 
                c = top[i]
                c ? c.ord : -1 # Value less than any code point, so that leading
                               # stack elements remain in place.
            }.map{|i| @state.stack[i] || ''}

        when :datetime
            push DateTime.now.strftime '%Y-%m-%dT%H:%M:%S.%L%:z'
        when :const_lf
            push "\n"
        when :const_empty
            push ""

        end
    end
end