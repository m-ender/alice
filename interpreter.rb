#!ruby --encoding utf-8:utf-8
# coding: utf-8

# Add stable sorting methods to Enumerable
module Enumerable
  def stable_sort
    sort_by.with_index { |x, idx| [x, idx] }
  end

  def stable_sort_by
    sort_by.with_index { |x, idx| [yield(x), idx] }
  end
end

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