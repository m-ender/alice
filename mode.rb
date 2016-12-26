# coding: utf-8

require_relative 'point2d'
require_relative 'direction'

class Mode
    # List of operators which should not be ignored while in string mode.
    STRING_CMDS = "\"'\\/_|"

    def initialize(state)
        @state = state
    end
    
    def do_tick
        cmd = @state.cell
        if @state.string_mode
            if cmd >= 0 && cmd <= 1114111 && STRING_CMDS[cmd.chr]
                case cmd.chr
                when '"'
                    @state.string_mode = false
                    process_string
                    @state.current_string = []
                when "'"
                    move
                    @state.current_string << @state.cell
                else
                    process(self.class::OPERATORS[cmd.chr], cmd)
                end
            else
                @state.current_string << cmd
            end
        else
            opcode = :nop
            opcode = self.class::OPERATORS[cmd.chr] if cmd >= 0 && cmd <= 1114111 # maximum Unicode code point

            process(opcode, cmd)
        end

        move
        @state.tick += 1
    end

    def process
        raise NotImplementedError
    end

    def process_string
        raise NotImplementedError
    end

    def move
        raise NotImplementedError
    end

    def push val
        @state.push val
    end

    def pop
        raise NotImplementedError
    end

    def peek
        val = pop
        push val
        val
    end

    def shift
        raise NotImplementedError
    end

    def unshift val
        @state.unshift val
    end

    def peek
        raise NotImplementedError
    end

end

class Cardinal < Mode
    OPERATORS = {
        ' '  => :nop,
        '@'  => :terminate,

        '/'  => :mirror,
        '\\' => :mirror,
        '_'  => :wall,
        '|'  => :wall,
        
        '<'  => :move_west,
        '>'  => :move_east,
        '^'  => :move_north,
        'v'  => :move_south,

        '{'  => :turn_left,
        '}'  => :turn_right,
        
        '#'  => :trampoline,
        '?'  => :cond_trampoline,

        '0'  => :digit, '1'  => :digit, '2'  => :digit, '3'  => :digit, '4'  => :digit, '5'  => :digit, '6'  => :digit, '7'  => :digit, '8'  => :digit, '9'  => :digit,
        '+'  => :add,
        '-'  => :sub,
        '*'  => :mul,
        ':'  => :div,
        '%'  => :mod,

        '['  => :mp_left,
        ']'  => :mp_right,
        
        '"'  => :string_mode,
        "'"  => :escape,

        'i'  => :input,
        'o'  => :output,

        'A'  => :bitand,
        'N'  => :bitnot,
        'O'  => :bitor,
        'X'  => :bitxor,

        #'('  => ,
        #')'  => ,

        #'!'  => ,
        #'$'  => ,
        #'&'  => ,
        #','  => ,
        #'.'  => ,
        #';'  => ,
        #'='  => ,
        #'~'  => ,
        #'`'  => ,

        #'A'  => ,
        # ...
        #'Z'  => ,
        #'a'  => ,
        # ...
        #'z'  => ,
    }

    OPERATORS.default = :nop

    def move
        @state.ip += @state.dir.vec
        @state.wrap
    end

    def pop
        val = nil

        loop do
            val = @state.pop
            if val.is_a?(String)
                found = false
                val.scan(/-?\d+/) { push $&.to_i; found = true }
                next if !found
                val = @state.pop
            end

            break
        end

        val || 0
    end

    def process_string
        @state.stack += @state.current_string
    end

    def process opcode, cmd
        case opcode
        when :terminate
            @state.done = true
        when :mirror
            @state.dir = @state.dir.reflect cmd.chr
            @state.set_ordinal
        when :wall
            @state.dir = @state.dir.reflect cmd.chr
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

        when :mp_left
            @state.mp -= 1
        when :mp_right
            @state.mp += 1

        when :string_mode
            @state.string_mode = true
        when :escape
            move
            push @state.cell

        when :input
            char = @state.in_str.getc
            push(char ? char.ord : -1)
        when :output
            @state.out_str << pop.chr

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
        when :bitand
            push(pop & pop)
        when :bitnot
            push(~pop)
        when :bitor
            push(pop | pop)
        when :bitxor
            push(pop ^ pop)

        end
    end
end

class Ordinal < Mode
    OPERATORS = {
        ' '  => :nop,
        '/'  => :mirror,
        '\\' => :mirror,
        '_'  => :wall,
        '|'  => :wall,
        '@'  => :terminate,

        '0'  => :digit, '1'  => :digit, '2'  => :digit, '3'  => :digit, '4'  => :digit, '5'  => :digit, '6'  => :digit, '7'  => :digit, '8'  => :digit, '9'  => :digit,
        '+'  => :concat,
        '-'  => :sub,
        '*'  => :riffle,
        ':'  => :split,
        '%'  => :mod,

        '<'  => :ensure_west,
        '>'  => :ensure_east,
        '^'  => :ensure_north,
        'v'  => :ensure_south,

        '{'  => :strafe_left,
        '}'  => :strafe_right,
        
        '#'  => :trampoline,
        '?'  => :cond_trampoline,
        
        '"'  => :string_mode,
        "'"  => :escape,

        'i'  => :input,
        'o'  => :output,

        #'('  => ,
        #')'  => ,

        #'['  => ,
        #']'  => ,

        #'!'  => ,
        #'$'  => ,
        #'&'  => ,
        #','  => ,
        #'.'  => ,
        #';'  => ,
        #'='  => ,
        #'?'  => ,
        #'`'  => ,
        #'~'  => ,

        #'A'  => ,
        # ...
        #'Z'  => ,
        #'a'  => ,
        # ...
        #'z'  => ,
    }

    OPERATORS.default = :nop

    def move
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

    def process_string
        # Will throw an error when cell isn't a valid code point
        push @state.current_string.map(&:chr)*''
    end

    def process opcode, cmd
        case opcode
        when :terminate
            @state.done = true
        when :mirror
            @state.dir = @state.dir.reflect cmd.chr
            @state.set_cardinal
        when :wall
            @state.dir = @state.dir.reflect cmd.chr
        when :ensure_west
            @state.dir = @state.dir.reflect cmd.chr if @state.dir.x > 0
        when :ensure_east
            @state.dir = @state.dir.reflect cmd.chr if @state.dir.x < 0
        when :ensure_north
            @state.dir = @state.dir.reflect cmd.chr if @state.dir.y > 0
        when :ensure_south
            @state.dir = @state.dir.reflect cmd.chr if @state.dir.y < 0
        when :strafe_left
            @state.ip += (@state.dir.reverse + @state.dir.left) / 2
        when :strafe_right
            @state.ip += (@state.dir.reverse + @state.dir.right) / 2
        when :trampoline
            move
        when :cond_trampoline
            move if pop == ''

        when :string_mode
            @state.string_mode = true
        when :escape
            move
            push @state.cell.chr # Will throw an error when cell isn't a valid code point

        when :digit
            push(pop + cmd.chr)
        when :input
            line = @state.in_str.gets
            push(line ? line.chomp : '')
        when :output
            @state.out_str << pop

        when :concat
            push(pop + pop)
        when :riffle
            sep = pop
            push(pop.chars * sep)
        when :split
            sep = pop
            $state.stack += pop.split(sep, -1)
        end
    end
end