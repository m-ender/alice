# Alice

"...the slithy toves did gyre and gimble in the wabe." — Lewis Carroll

Alice is a two-dimensional, stack-based, recreational programming language. It was designed as a feature-rich [Fungeoid](https://esolangs.org/wiki/Fungeoid) with many useful (and some not so useful) commands which make it comparably usable for a 2D language. To this end, depending on whether the instruction pointer moves orthogonally or diagonally, Alice operates either in an integer mode or in a string mode, which allows every operator to be overloaded with two different commands.

## Overview

This section introduces some general concepts about Alice's programming model.

One quick definition up front: Alice considers an integer value to be a *character* if it is in the inclusive range [0, 1114111], which is the entire range of Unicode code points.

### Source code and grid

The source file is assumed to be encoded as UTF-8. And linefeeds (0x0A) are considered to be the only line separators. If the lines aren't all of the same length, the shorter ones are padded on the right with spaces (0x20). If the file is empty it is treated as a file containing a single space.

Each character is then converted to its Unicode code point and the resulting values are placed on an infinite 2D grid. The first character of the source file goes at coordinate **(0,0)**, the **x** coordinate increases along lines (to the right) and the **y** coordinate increases across lines (downwards). Any cells not covered by the (padded) source file are filled with `-1`.

For example the following source file...

    ABC
    D
    EF

...would lead to the following initial grid:

       x ... -2 -1  0  1  2  3  4  ...
     y
    ...
    -2       -1 -1 -1 -1 -1 -1 -1
    -1       -1 -1 -1 -1 -1 -1 -1
     0       -1 -1 65 66 67 -1 -1
     1       -1 -1 68 32 32 -1 -1
     2       -1 -1 69 70 32 -1 -1
     3       -1 -1 -1 -1 -1 -1 -1
     4       -1 -1 -1 -1 -1 -1 -1
    ...

While it's possible to access the entire unbounded grid over the course of program execution, in the following *"the grid"* will refer to the smallest rectangle that contains all values which aren't `-1`. There will always be a finite number of such cells, so this is well-defined. However, the grid *may* grow or shrink during program execution if the grid values are modified such that the bounding box of non-`-1` cells changes.

Characters and their character codes will be used interchangeably when it comes to cells in the remainder of this document. So a cell containing the value `65` might also be referred to as a cell containing `A`.

There are a few different types of grid cells. Their exact meanings will be explained below, but we'll define them here:

- **No-ops:** Spaces (0x20), backticks (`` ` ``, 0x60) and every value which is *not* in the printable ASCII range (0x20 to 0x7E) is considered a no-op. They generally don't do anything (except backticks) and are treated specially during movement.
- **Geometry:** `_` and `|` are **walls** and `/` and `\` are **mirrors**. In particular, these are not considered to be commands (as in most other Fungeoids) but have a special status and are considered to be part of the "geometry" of the grid.
- **Commands:** Every other printable ASCII character is considered to be a command. `'` and `"` have a somewhat special status among these, but we'll get to those when we talk about movement.

### Cardinal and Ordinal mode

Alice's defining feature is that it can operate in two different modes:

- If the instruction pointer is moving horizontally or vertically, Alice operates in **Cardinal mode**. In this mode, Alice treats all data as integers and can perform operations related to arithmetic, number theory, combinatorics etc.
- If the instruction pointer is moving diagonally, Alice operates in **Ordinal mode**. In this mode, Alice treats all data as strings and can perform operations related to string processing, array manipulation and set theory (treating strings as lists or multisets of characters).

Alice switches between the two modes by stepping through *mirrors* (of course). Consequently, the two modes were designed to feel somewhat like two parallel universes, where many things look and feel the same but are actually subtly (or not so subtly) different. Every command (except for some very basic stack manipulation) has two different meanings in the two modes, movement works somewhat differently and memory is interpreted in a different way.

### Memory model

Alice's memory model spans three types of storage.

#### Data types

There are two data types in Alice: arbitrary-precision signed integers and strings. A string is simply a list of characters (as defined above).

#### Grid

We've already seen the grid as the way the source code is interpreted. However, the grid can be written to and read from (even outside of the bounds of the initial grid), which means that it doubles as memory storage. Each cell can hold a single integer.

#### Stack

As a stack-based language, Alice's primary memory storage is a single [stack](https://en.wikipedia.org/wiki/Stack_(abstract_data_type)). The stack can hold both integers and strings. However, Cardinal mode and Ordinal mode only know about one of these types. So when they try pop a value, Alice might implicitly convert the value to the appropriate type. The rules for this conversion are as follows.

If a string is popped in Cardinal mode, Alice finds all integers in this string. Integers are substrings consisting only of ASCII digits, optionally prefixed by a `-`. However, if the `-` immediately follows an earlier integer, it is ignored. An example might help: in `ab12,-34cd`, Alice would find the integers `12` and `-34`. But in `ab12-34cd` it would find the integers `12` and `34` instead. All of these integers are pushed to the stack (from left to right), and then Alice tries to pop a value again. Note that if the string on top of the stack contains no integers, it will simply be discarded and Alice pops the next value instead (which may again be a string which would repeat the process).

If Alice tries to pop from an empty stack in Cardinal mode, a zero is returned instead.

If an integer is popped in Ordinal mode, Alice simply converts that integer to its usual decimal string representation.

If Alice tries to pop from an empty stack in Ordinal mode, an empty string is returned instead.

Note that there are few stack manipulation commands which reorder the stack *without* popping any values. Consequently, these don't cause any type conversion. This will be pointed out explicitly in the command reference, where applicable.

#### Tape

As a secondary memory storage, Alice has an infinite tape of integers. As opposed to a tape-based language like [Brainfuck](http://esolangs.org/wiki/Brainfuck), Alice's tape is more used like an unlimited amount of registers. Data can be copied to and from the tape but cannot be manipulated directly on the tape. The tape is initially filled with the value `-1` in every cell.

There are two independent tape heads (or memory pointers), one for Cardinal mode and one for Ordinal mode. When the current mode is clear from the context, the corresponding one will just be referred to as "the tape head". Initially, both tape heads point at the cell at index zero.

Cardinal and Ordinal mode treat the data on the tape differently. Whereas Cardinal mode just considers each cell as a separate integer, Ordinal mode treats the longest sequence of characters from the tape head to the right as a string. Correspondingly, moving the Ordinal tape head moves it by entire strings. The details will be explained for the relevant commands below.

### Additional state

Apart from the the memory storages above, there are a few more pieces of program state in Alice, which are described in this section.

#### Instruction pointer

Control flow in Alice is governed by an instruction pointer (**IP**), which has a position on the grid as well as a direction. To avoid confusion with directions relative to the IP, we'll use *north* (**-y**), *east* (**+x**), *south* (**+y**) and *west* (**-x**) to refer to absolute directions on the grid.

#### Return address stack

Alice has an internal stack of grid coordinates which are used as return addresses. These allow you to implement reusable subroutines relatively conveniently. Note that all of this is only by convention. Alice has no concept of scope, and there is nothing stopping the IP from leaving a subroutine "on its own" without making use of the return address stack. The stack is merely a convenience so that the programmer does not have to keep track of where to resume execution of the code manually.

The return address stack is initially empty and can hold pairs of integers, i.e. (x,y) coodinates on the grid. Note in particular that the return address stack stores no information about the IP's direction.

If a command attempts to pop from this stack when it's empty, the current position of the IP will be returned instead (which essentially makes "return" commands on an empty stack no-ops).

#### Iterator queue

While normally each command in Alice is executed once when the IP passes over it, Alice has **iterators** which let you execute a command multiple times in a row. 

There is an internal [queue](https://en.wikipedia.org/wiki/Queue_(abstract_data_type)), which can hold integers and strings and which is initially empty. If the queue is empty, the default iterator is **1**. The detailed semantics of these iterators are explained below in the section on executing commands.

### Movement

The IP is initially at coordinate (-1,0), i.e. left of the first character of the program, moving east. Because the IP always moves before a command is executed, this effectively means the program starts at coordinate (0,0), as you'd expect.

Alice is executed in "ticks" where each tick consists of a move, followed by executing a command. A move consists of one or more steps and essentially scans the grid for the next command in the direction of the IP. However, grid geometry (i.e. walls, mirrors or boundaries) may change the direction of the IP and even the mode while it moves.

There is a special case if the IP is initially on a cell containing `'`. If this is the case, the IP will move one step, completely ignoring the contents of the next cell (whether they are no-op, geometry or command, even another `'`), before starting its usual scan for the next command. This is because `'` is an "escaping" command which also consumes the next cell.

If the IP encounters the special command `"` on its search, it will activate **string mode**, which is described in more detail below. Activating string mode is not considered a command (although deactivating it is).

#### No-ops

The IP skips over all no-ops while it searches for the next command. However, there is one special no-op here: the backtick, `` ` ``. Whenever the IP passes over a backtick, Alice prints debug information about all relevant program state to the standard error stream. The exact representation is up to the interpreter, but it should contain all of Alice's state. Interpreters with interactive debuggers may instead choose to interpret backticks as breakpoints.

#### Walls

These are simplest: if the IP encounters `_` or `|` during a move, its direction gets reflected as you'd expect. In Cardinal mode, `_` is ignored for horizontal movement and `|` reverses the direction (and vice-versa for vertical movement). In Ordinal mode, they change the direction by 90 degrees, e.g. `_` changes southeast movement to northeast etc.

#### Mirrors

Mirrors, `/` and `\`, are a staple in 2D languages, but in Alice they work a bit differently than you probably expect. First of all, in Alice the IP moves *through* mirrors and doesn't get reflected at them. But secondly, Alice acknowledges that the characters `/` and `\` are rarely displayed at 45 degree angles, so having them cause 90 degree reflections is somewhat unfitting. The angles in many fonts are actually closer to 67.5 degrees, and therefore mirrors reflect between orthogonal and diagonal movement in Alice.

Unfortunately, this may look slightly confusing in the source code at first, because most fonts (even monospaced ones) also don't have square character cells. Therefore, here are two diagrams which visualise how the IP moves through a mirror, coming from a horizontal or vertical direction:

![Movement through mirrors][mirrors]

If this reflection seems weird (especially the second one), imagine holding a long straight stick with one end to the surface of a mirror. The IP comes in along that stick and when it hits the surface of the mirror it goes "into" the mirror and continues along the reflection of the stick.

All other possible directions for hitting the mirror are completely symmetric to one of the above two diagrams (you either reverse the direction of the IP, rotate the diagram by 180 degrees, or mirror it horizontally).

Note that this always changes orthogonal movement to diagonal movement and vice versa. Therefore, mirrors always toggle between Cardinal mode and Ordinal mode, and they are also the *only* way in the language to switch between modes.

  [mirrors]: https://i.stack.imgur.com/zXs4J.png

#### Boundaries

While the IP is moving it may happen that it tries to move to a cell outside of the grid (i.e. beyond the bounding box of non-background cells in the unbounded grid).

How Alice handles this situation depends on whether we are in Cardinal mode and Ordinal mode.

Cardinal mode uses wrapping boundaries like many other Fungeoids. If the IP is out of bounds after a step, it moves to the beginning of the line (which may be a row or column) along which it is currently moving instead. Note that this means that if the IP moves alongside the grid (instead of away from it or towards it), it will be stuck outside the grid forever. This situation can be caused by some of the control flow commands, or if the grid shrinks while the IP moves along its edge.

Ordinal mode uses solid boundaries instead, which act similarly to walls. If the IP would move out of bounds with the current step, its direction will instead be reflected on the boundary before taking the step. If the IP would move through a corner of the grid, its direction gets reversed.

If the grid is only one cell tall or wide, it is not possible for the IP to take any diagonal steps so the IP will remain in place. If the current cell is a command, that command would get executed over and over again (but setting this up is quite non-trivial and should be considered a tremendous edge case). If the IP manages to end up out of bounds (which is also a very unlikely edge case), it will be stuck there forever.

### Commands

Once movement ends and the IP has found a command, that command will be executed. When a command needs to be executed, Alice first dequeues an iterator from the iterator queue. Remember that if the queue is empty, the default iterator is **1** (which in effect means that the command is simply executed once as you'd expect).

How the command is executed depends on the iterator:

- **Repetition:** If the iterator is a positive integer **N**, the command is executed **N** times (without moving the IP in between, unless the command itself causes movement). For non-positive integers, the command isn't executed at all.
- **Folding:** If the iterator is a string, Alice goes through each character in the string from left to right and then a) pushes that character to the stack (which we'll get to in the next section) and b) executes the current command once. Note that if the iterator is an empty string this also means that the command isn't executed at all.

The iterator queue will normally contain at most one value, which lets you execute the next command multiple times. However, if that next command itself adds iterators to the queue, it's possible to have multiple iterators queued up at once.

### String mode

Finally, there is string mode, which can be entered and exited with the special `"` command. In string mode, Alice no longer executes any of the usual commands but instead remembers each character it passes over until string mode ends again. However, a few characters retain their special meaning:

- `'` still escapes the next cell. The `'` itself is not added to the string, but the subsequent cell is, even if it's a special character.
- Mirrors and walls (i.e. any of `/\_|`) still redirect the IP without being added to the string, unless they are escaped with `'`. In particular, this means that it's possible to switch between Cardinal and Ordinal mode while string mode is active.
- `"` ends string mode (unless it's escaped) and processes the string.

Remember that entering string mode is not considered a command for the purpose of iterators, but leaving string mode does. The consequences are that leaving string mode dequeues an iterator (and therefore may process the string several times), and how the string is processed depends on whether we're in Cardinal or Ordinal mode at the time of leaving string mode.

If string mode ends in Cardinal mode, the resulting command pushes the code point of each character in the string once as an integer to the stack.

If string mode ends in Ordinal mode, the resulting command pushes the entire string to the stack.

## Command reference

*coming soon*