# coding: utf-8

require_relative 'alice'

debug_level = 0

ARGV.select!{|arg|
    if arg[0] == '-'
        debug_level = 1 if arg[/d/]
        debug_level = 2 if arg[/D/]

        false
    else
        true
    end
}

source = ARGF.read

begin
    Alice.run(source, debug_level)
rescue => e
    $stderr.puts e.message
end