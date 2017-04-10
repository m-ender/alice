#!ruby --encoding utf-8:utf-8
# coding: utf-8

require_relative 'alice'

source = ARGF.read

alice = Alice.new(source)

begin
    alice.run
rescue => e
    alice.state.print_debug_info
    $stderr.puts e.message
    $stderr.puts e.backtrace
end