#!ruby --encoding utf-8:utf-8
# coding: utf-8

require_relative 'alice'

if ARGV.size == 0
    puts "Usage: ruby interpreter.rb source.alice [args ...]"
else
    source = File.read(ARGV.shift)

    alice = Alice.new(source)

    begin
        alice.run
    rescue => e
        alice.state.print_debug_info
        $stderr.puts e.message
        $stderr.puts e.backtrace
    end
end