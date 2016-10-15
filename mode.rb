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
        @state.stack << val
    end

    def pop
        raise NotImplementedError
    end

    def shift
        raise NotImplementedError
    end

    def unshift val
        @state.stack.unshift val
    end

    def peek
        raise NotImplementedError
    end

    def read_byte
        result = nil
        if @next_byte
            result = @next_byte
            @next_byte = nil
        else
            result = @in_str.getc
        end
        result
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

        #'('  => ,
        #')'  => ,

        #'!'  => ,
        #'#'  => ,
        #'$'  => ,
        #'&'  => ,
        #','  => ,
        #'.'  => ,
        #';'  => ,
        #'='  => ,
        #'?'  => ,
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

    def process opcode, cmd
        case opcode
        when :terminate
            @state.done = true
        when :mirror
            @state.dir = @state.dir.reflect cmd.chr
            @state.set_ordinal
        when :wall
            @state.dir = @state.dir.reflect cmd.chr
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

        '<'  => :rotate_west,
        '>'  => :rotate_east,
        '^'  => :rotate_north,
        'v'  => :rotate_south,

        '{'  => :strafe_left,
        '}'  => :strafe_right,
        
        '"'  => :string_mode,
        "'"  => :escape,

        #'('  => ,
        #')'  => ,

        #'['  => ,
        #']'  => ,

        #'!'  => ,
        #'#'  => ,
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

    def process opcode, cmd
        case opcode
        when :terminate
            @state.done = true
        when :mirror
            @state.dir = @state.dir.reflect cmd.chr
            @state.set_cardinal
        when :wall
            @state.dir = @state.dir.reflect cmd.chr
        end
    end
end