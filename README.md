# Alice

"...the slithy toves did gyre and gimble in the wabe." — Lewis Carroll

Alice is a two-dimensional, stack-based, recreational programming language. It was designed as a feature-rich [Fungeoid](https://esolangs.org/wiki/Fungeoid) with many useful (and some not so useful) commands which make it comparably usable for a 2D language. To this end, depending on whether the instruction pointer moves orthogonally or diagonally, Alice operates either in an integer mode or in a string mode, which allows every operator to be overloaded with two different commands.

## Language concepts

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

The parallels between Cardinal and Ordinal mode were designed with a few themes in mind. For example, Ordinal-mode commands which work with substrings are often paired with similar Cardinal-mode commands that work with divisors, bitwise commands are paired set-theoretic commands and so on.

### Memory model

Alice's memory model spans three types of storage.

#### Data types

There are two data types in Alice: arbitrary-precision signed integers and strings. A string is simply a list of characters (as defined above).

#### Grid

We've already seen the grid as the way the source code is interpreted. However, the grid can be written to and read from (even outside of the bounds of the initial grid), which means that it doubles as memory storage. Each cell can hold a single integer.

#### Stack

As a stack-based language, Alice's primary memory storage is a single [stack](https://en.wikipedia.org/wiki/Stack_(abstract_data_type)). The stack can hold both integers and strings. However, Cardinal mode and Ordinal mode only know about one of these types. So when they try pop a value, Alice might implicitly convert the value to the appropriate type. The rules for this conversion are as follows.

If a string is popped in Cardinal mode, Alice finds all integers in this string. Integers are substrings consisting only of ASCII digits, optionally prefixed by a `-`. However, if the `-` immediately follows an earlier integer, it is ignored. An example might help: in `ab12,-34cd`, Alice would find the integers `12` and `-34`. But in `ab12-34cd` it would find the integers `12` and `34` instead. All of these integers are pushed to the stack (from left to right), and then Alice tries to pop a value again. Note that if the string on top of the stack contains no integers, it will simply be discarded and Alice pops the next value instead (which may again be a string which would repeat the process).

If Alice tries to pop from an empty stack in Cardinal mode, a zero is returned instead. Likewise, commands which work with the stack without popping treat it as if there as in infinite amount of zeros at the bottom.

If an integer is popped in Ordinal mode, Alice simply converts that integer to its usual decimal string representation.

If Alice tries to pop from an empty stack in Ordinal mode, an empty string is returned instead. Likewise, commands which work with the stack without popping treat it as if there as in infinite amount of empty strings at the bottom.

Note that there are few stack manipulation commands which reorder the stack *without* popping any values. Consequently, these don't cause any type conversion. This will be pointed out explicitly in the command reference, where applicable.

#### Tape

As a secondary memory storage, Alice has an infinite tape of integers. As opposed to a tape-based language like [Brainfuck](http://esolangs.org/wiki/Brainfuck), Alice's tape is more used like an unlimited amount of registers. Data can be copied to and from the tape but cannot be manipulated directly on the tape. The tape is initially filled with the value `-1` in every cell.

There are two independent tape heads (or memory pointers), one for Cardinal mode and one for Ordinal mode. When the current mode is clear from the context, the corresponding one will just be referred to as "the tape head". Initially, both tape heads point at the cell at index zero.

Cardinal and Ordinal mode treat the data on the tape differently. Whereas Cardinal mode just considers each cell as a separate integer, Ordinal mode treats the tape as a tape of words.

**Words** are defines as consecutive runs of cells that correspond to characters, terminated by a cell that *isn't* a character. Therefore negative values and values greater than **1114111** are considered word terminators. If there are two adjacent non-character cells, the latter represents an empty word.

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

If the grid is only one cell tall or wide, it is not possible for the IP to take any diagonal steps so the IP will remain in place. If the current cell is a command, that command would get executed over and over again (but setting this up is quite non-trivial and should be considered a tremendous edge case). If the IP manages to end up out of bounds by more than one cell (which is also a very unlikely edge case), it will be stuck there forever.

### Commands

Once movement ends and the IP has found a command, that command will be executed. When a command needs to be executed, Alice first dequeues an iterator from the iterator queue. Remember that if the queue is empty, the default iterator is **1** (which in effect means that the command is simply executed once as you'd expect).

How the command is executed depends on the iterator:

- **Repetition:** If the iterator is a positive integer **N**, the command is executed **N** times (without moving the IP in between, unless the command itself causes movement). For non-positive integers, the command isn't executed at all.
- **Folding:** If the iterator is a string, Alice goes through each character in the string from left to right and then a) pushes that character to the stack (which we'll get to in the next section) and b) executes the current command once. Note that if the iterator is an empty string this also means that the command isn't executed at all.

The iterator queue will normally contain at most one value, which lets you execute the next command multiple times. However, if that next command itself adds iterators to the queue, it's possible to have multiple iterators queued up at once.

Some commands can put a **0** at the front of the queue (so it's not a strict queue), in order to skip the next command.

### String mode

Finally, there is string mode, which can be entered and exited with the special `"` command. In string mode, Alice no longer executes any of the usual commands but instead remembers each character it passes over until string mode ends again. However, a few characters retain their special meaning:

- `'` still escapes the next cell. The `'` itself is not added to the string, but the subsequent cell is, even if it's a special character.
- Mirrors and walls (i.e. any of `/\_|`) still redirect the IP without being added to the string, unless they are escaped with `'`. In particular, this means that it's possible to switch between Cardinal and Ordinal mode while string mode is active.
- `"` ends string mode (unless it's escaped) and processes the string.

Remember that entering string mode is not considered a command for the purpose of iterators, but leaving string mode does. The consequences are that leaving string mode dequeues an iterator (and therefore may process the string several times), and how the string is processed depends on whether we're in Cardinal or Ordinal mode at the time of leaving string mode.

If string mode ends in Cardinal mode, the resulting command pushes the code point of each character in the string once as an integer to the stack.

If string mode ends in Ordinal mode, the resulting command pushes the entire string to the stack.

### Labels

While Cardinal mode uses integer coordinate pairs to address cells in the grid (e.g. to manipulate the grid or for certain control flow commands), Ordinal mode has no concept of integers. Instead, Ordinal mode uses **labels** to refer to positions on the grid.

A label is just a string that appears somewhere on the grid, but since Ordinal mode operates along diagonals, labels are also searched for along diagonals. When a command tries to find a certain label, it effectively rotates the grid by a multiple of 45 degrees so that the IP points east, and then searches for the label in normal (left-to-right, top-to-bottom) reading order. To make it explicit, the following four grids show in which order the grid is scanned depending on the IP's current direction:

    Direction:   SE    SW    NW    NE

    Scanning    gdba  pnkg  jmop  acfj
    order:      khec  olhd  filn  beim
                nlif  mieb  cehk  dhlo
                pomj  jfca  abdg  gknp

Note that labels cannot span multiple lines. For example, it would not be possible to find the label `cde` in any of the above grids. Alice will only search the strings `a`, `bc`, `def`, `ghij`, `klm`, `no` and `p` for the label. Commands will either refer to the cell after the label (along its diagonal), or to the one directly before that (so in general, the end of the label is the relevant reference point). The exact usage of the label is described below for the relevant commands.

## Command reference

This section lists all the commands available in Alice, roughly grouped into a few related categories. For the sake of completeness, the non-commands `` ` `` (which is a special no-op), `/\_|` (which are mirrors and walls) and the special commands `'` and `"` are listed here again, but remember that they are treated differently for the purposes of movement.

If the reference says "Pop **n**" in Cardinal mode, **n** is always an integer. In Ordinal mode, it's always a string. See the section on the **Stack** for details of potentially required type conversions. In general, **n** will be used as the variable of single integer parameters, and **x**, **y**, **z** if there are several. Similarly, **s** will be used for a single string parameter, and **a**, **b**, **c** if there are several. There are some exceptions, where other variables are more conventional, like using **n** and **k** in the context of combinatorics.

When the reference refers to pushing individual characters to the stack, this refers to strings containing only that character.

### Debugging

Cmd | Cardinal | Ordinal
--- | -------- | -------
`` ` `` | Special no-op: prints debug information to the standard error stream. | Same as Cardinal.

### Control flow

Cmd | Cardinal | Ordinal
--- | -------- | -------
`@` | Terminate the program. | Terminate the program.
`/` | Reflect the IP through 67.5 degrees, switch between modes. See section on **Mirrors** for details. | Same as Cardinal.
`\` | Reflect the IP through -67.5 degrees, switch between modes. See section on **Mirrors** for details. | Same as Cardinal.
`_` | Reflect the IP through 0 degrees. See section on **Walls** for details. | Same as Cardinal.
`\|` | Reflect the IP through 90 degrees. See section on **Walls** for details. | Same as Cardinal.
`<` | Set the IP direction to west. | Set the IP direction to southwest (northwest) if the IP is moving southeast (northeast).
`>` | Set the IP direction to east. | Set the IP direction to southeast (northeast) if the IP is moving southwest (northwest).
`^` | Set the IP direction to north. | Set the IP direction to northwest (northeast) if the IP is moving southwest (southeast).
`v` | Set the IP direction to south. | Set the IP direction to southwest (southeast) if the IP is moving northwest (northeast).
`{` | Turn the IP direction left by 90 degrees. | Turn the IP direction left by 90 degrees.
`}` | Turn the IP direction right by 90 degrees. | Turn the IP direction right by 90 degrees.
`=` | Pop **n**. Act like `{` if **n** is negative, like `}` if **n** is positive. Has no further effect if **n = 0**. | Pop **b**. Pop **a**. Act like `{` if **a < b**, act like `}` if **a > b**. Has no further effect if **a = b**. Comparisons are based on the lexicographic ordering of the strings.
`#` | Skip the next command. This is implemented by adding a **0** to the *front* of the iterator queue. | Same as Cardinal. (Technically, this one uses **""** as the iterator, but **""** and **0** are functionally equivalent as iterators.)
`$` | Pop **n**. Act like `#` if **n = 0**, do nothing otherwise. | Pop **s**. Act like `#` if **s = ""**, do nothing otherwise.
`j` | Pop **y**. Pop **x**. Push the current IP address to the return address stack. Jump to **(x,y)**.<sup>\*</sup> | Pop **s**. Search the grid for the label **s**. If the label is not found, do nothing. Otherwise, push the current IP address to the return address stack and jump to the last cell of the label.<sup>\*</sup>
`J` | Same as `j`, but does not push the current IP to the return address stack.<sup>\*</sup> | Same as `j`, but does not push the current IP to the return address stack.<sup>\*</sup>
`k` | Pop an address from the return address stack and jump there.<sup>\*</sup> | Same as Cardinal.
`K` | Peek at the top of the return address stack and jump there.<sup>\*</sup> | Same as Cardinal.
`w` | Push the current IP address to the return address stack (without jumping anywhere). | Same as Cardinal.
`W` | Pop and discard the top of the return address stack. | Same as Cardinal.
`&` | Pop **n**. Add **n** to the iterator queue. | Pop **s**. Add **s** to the iterator queue.

<sup>\*</sup> Remember that the IP will then move *before* the next command is executed.

### Literals and constants

Cmd | Cardinal | Ordinal
--- | -------- | -------
`"` | Toggles string mode. Only exiting string mode is considered a command, and pushes the individual code points of the string to the stack. See the section on **String mode** for details. | Toggles string mode. Only exiting string mode is considered a command, and pushes the entire string to the stack. See the section on **String mode** for details. 
`'` | Pushes the code point of the next grid cell to the stack.<sup>†</sup>  | Pushes the character in the next grid cell to the stack.<sup>†</sup>
`0-9` | Pushes the corresponding digit to the stack. | Pop **s**. Append the corresponding digit as a character to **s** and push the result.
`a` | Push **10**. | Push a single linefeed character (0x0A).
`e` | Push **-1**. | Push an empty string.

<sup>†</sup> The next cell will be skipped by the subsequent move, but not as part of the command. This distinction is important when working with iterators. 

### Input and output

Cmd | Cardinal | Ordinal
--- | -------- | -------
`i` | Read a single byte from the standard input stream and push it. | Read the entire UTF-8-encoded standard input stream (until EOF is encountered) and push it as a single string.<sup>‡</sup>
`I` | Read a single UTF-8-encoded character from the standard input stream and push its code point.<sup>‡</sup> | Read one UTF-8-encoded line from the standard input stream (i.e. up to the first linefeed, 0x0A) and push it as a single string. The linefeed is consumed but not included in the resulting string.<sup>‡</sup>
`o` | Pop **n**. Write its 8 least significant bits as a byte to the standard output stream. | Pop **s**. Write it as a UTF-8-encoded string to the standard output stream.
`O` | Pop **n**. Write the UTF-8-encoded character with code point **n** to the standard output stream. | Pop **s**. Write it as a UTF-8-encoded string to the standard output stream, followed by a linefeed (0x0A).

<sup>‡</sup> This will skip any leading bytes that do not form a valid UTF-8 character.

### Grid manipulation


Cmd | Cardinal | Ordinal
--- | -------- | -------
`g` | Pop **y**. Pop **x**. Get the value in the grid cell at **(x,y)** and push it. | Pop **s**. Scan the grid for the label **s**. If the label was found, push everything after the label (on the same diagonal) as a single string.
`p` | Pop **v**. Pop **y**. Pop **x**. Set the value in the grid cell at **(x,y)** to **v**. | Pop **v**. Pop **s**. Starting at the cell after the label (on the same diagonal), write **v** onto the grid, one character per cell. If **v** is longer than the remainder of the diagonal, this will write over the edge of the grid and thereby extend the bounding box of the grid.

### Stack manipulation

Cmd | Cardinal | Ordinal
--- | -------- | -------
`,` | Pop **n**. If **n** is positive, move the element which is **n** elements below the top to the top. If **n** is negative, move the top stack element down the stack by **n** positions. These operations do not pop and push elements and therefore don't convert any data types. | Pop **s**. Use as a permutation to reorder the stack. This is done by aligning the string character-by-character with the stack elements, so that the last element corresponds to the top of the stack (and the first character corresponds to the **n**th element from the top, where **n** is the length of **s**). Then the string is sorted stably, while keeping each stack element paired with its corresponding character. Hence, the stack elements perform the reordering that is required to sort **s**. The reordered stack elements are not popped in the process, so this does not convert any data types.
`~` | Swap. Pop **y**. Pop **x**. Push **y**. Push **x**. | Swap. Pop **b**. Pop **a**. Push **b**. Push **a**.
`.` | Duplicate. Pop **n**. Push **n** twice. | Duplicate. Pop **s**. Push **s** twice.
`;` | Pop one integer and discard it. | Pop one string and discard it.
`Q` | Pop **n**. Pop **n** values and push them again, so that their order *remains the same*. This can be used to force conversion of stack elements from the top such that there are at least **n** integers on top of the stack (as opposed to strings). | Pop all stack elements and push them again, so that their order is *reversed*. This also forces conversion to strings, although there are no cases where an explicit conversion to strings can change the behaviour of a program.
`d` | Depth. Push the number of elements currently in the stack (without popping or converting any of them). | Make a copy of each stack element, convert it to a string, join them all together (so that the top element is at the end) and push the result. This does not affect any of the existing stack elements.

### Tape manipulation

Cmd | Cardinal | Ordinal
--- | -------- | -------
`!` | Pop **n**. Store it in the current tape cell. | Pop **s**. Store it as a word on the tape. In particular, store its characters on the tape, starting at the position of the tape head and going right. The cell right after the end of **s** gets set to **-1** to ensure that there is a word terminator.
`?` | Push the value in the current tape cell to the stack. | Read a word from the tape cell by taking the longest run of characters from the position of the tape head to the right and push it to the stack.
`[` | Move the tape head one cell to the left. | Move the tape head one word to the left. Specifically, move the tape head left as long as that cell holds a character (to move the tape head to the beginning of the current word) — this part will usually be skipped. Then move it one more cell to the left (to move it onto the previous word terminator). Then move it left again as long as that cell holds a character (to move the tape head to the beginning of the previous word).
`]` | Move the tape head one cell to the right. | Move the tape head one word to the right. Specifically, move the tape head right as long as the current cell holds a character (to move the tape head to the terminator of the current word). Then move it one more cell to the right (to move it onto the beginning of the next word).
`(` | Pop **n**. Search for **n** left of the tape head (excluding the current cell itself). If it is found, move the tape head to the nearest occurrence. | Pop **s**. Search for a word containing **s** as a substring left of the currently pointed to word (excluding that word itself). If such a word is found, move the tape head to its beginning.
`)` | Pop **n**. Search for **n** right of the tape head (excluding the current cell itself). If it is found, move the tape head to the nearest occurrence. | Pop **s**. Search for a word containing **s** as a substring right of the currently pointed to word (excluding that word itself). If such a word is found, move the tape head to its beginning.
`q` | Push the current *position* of the tape head. | Join all words on the tape into a single string and push it.

### Basic arithmetic and string operations

Cmd | Cardinal | Ordinal
--- | -------- | -------
`+` | Pop **y**. Pop **x**. Push **x + y**. | Pop **b**. Pop **a**. Push the concatenation of **a** and **b**.
`-` | Pop **y**. Pop **x**. Push **x - y**. | Pop **b**. Pop **a**. Remove all occurrences of **b** from **a** and push the result. If there are overlapping occurrences, the characters from all those occurrences will be removed (e.g. operands **"abcbcbd"** and **"bcb"** would yield **"ad"**).
`*` | Pop **y**. Pop **x**. Push **x * y**. | Pop **b**. Pop **a**. Insert **b** between every pair of characters in **a** and push the result.
`:` | Pop **y**. Pop **x**. Push **x / y**. Results are rounded towards negative infinity. Terminates the program with an error if **y = 0**. | Pop **b**. Pop **a**. Push all *non-overlapping* occurrences of **b** in **a** (e.g. operands **"abcbcbcbd"** and **"bcb"** would push **"bcb"** only twice).
`%` | Pop **y**. Pop **x**. Push **x % y** (modulo). The sign of the result matches the sign of **y**, such that **(x / y) * y + x % y = x** is guaranteed. Terminates the program with an error if **y = 0**. | Pop **b**. Pop **a**. Split **a** into chunks separated by occurrences of **b** and push those chunks.
`E` | Pop **y**. Pop **x**. Push **x<sup>y</sup>**. If **x = y = 0**, push **1**. If **y** is negative, round the result towards negative infinity. | ???
`H` | Pop **n**. Push **\|n\|**. | Trim. Pop **s**. Remove all tabs (0x09), linefeeds (0x0A) and spaces (0x20) from both ends of the string.
`M` | Divmod. Pop **y**. Pop **x**. Push both **x / y** and **x % y**. See commands `:` and `%` for details. | Pop **b**. Pop **a**. Split **a** before and after each non-overlapping occurrence of **b** and push the individual chunks.
`R` | Pop **n**. Push **-n**. | Pop **s**. Reverse **s** and push the result.
`h` | Pop **n**. Push **n+1**. | Pop **s**. Push the first character of **s**, then push the remainder of **s**. If **s == ""**, push **""** twice.
`t` | Pop **n**. Push **n-1**. | Pop **s**. Push the everything except the last character of **s**, then push the last character of **s**. If **s == ""**, push **""** twice.
`m` | Pop **y**. Pop **x**. Push the greatest multiple of **y** which is not greater than **x**. | Pop **b**. Pop **a**. Remove characters from the longer string of the two until they have the same length. Push **a**. Push **b**.
`n` | Pop **y**. Push **1** if **y = 0**, push **0** otherwise. | Pop **s**. Push **"Jabberwocky"** if **s = ""**, push **""** otherwise.
`Y` | Unpack. Pop **n**. Map **n** (bijectively) to two integers **x** and **y**. Push **x** and **y**. This is the inverse operation of `Z`. For details of the bijection, see the footnote.<sup>§</sup> | Unzip. Pop **s**. Create two empty strings **a** and **b**. Append the characters from **s** to **a** and **b** in an alternating manner, starting with **a**. Push **a**. Push **b**.
`Z` | Pack. Pop **y**. Pop **x**. Map **x** and **y** (bijectively) to a single integer **n**. Push **n**. This is the inverse operation of `Y`. For details of the bijection, see the footnote.<sup>§</sup> | Zip. Pop **b**. Pop **a**. Interleave **a** and **b** by taking characters from then in an alternating manner, starting with **a**. If one string is shorter than the other, the remaining characters of the other one are simply appended. For example **a = "abc"** and **b = "012345"** will yield **"a0b1c2345"**. Push the result.

<sup>§</sup> The details of the bijection are likely irrelevant for most use cases. The main point is that it lets the user encode two integers in one and extract the two integers again later on. By applying the pack command repeatedly, entire lists or trees of integers can be stored in a single number (although not in a particularly memory-efficient way). The mapping computed by the pack operation is a bijective function **ℤ<sup>2</sup> → ℤ** (i.e. a one-to-one mapping). First, the integers **{..., -2, -1, 0, 1, 2, ...}** are mapped to the natural numbers (including zero) like **{..., 3, 1, 0, 2, 4, ...}** (in other words, negative integers are mapped to odd naturals and non-negative integers are mapped to even naturals). The two natural numbers are then mapped to one via the [Cantor pairing function](https://en.wikipedia.org/wiki/Pairing_function), which writes the naturals along the diagonals of the first quadrant of the integer grid. Specifically, **{(0,0), (1,0), (0,1), (2,0), (1,1), (0,2), (3,0), ...}** are mapped to **{0, 1, 2, 3, 4, 5, 6, ...}**. The resulting natural number is then mapped back to the integers using the inverse of the earlier bijection. The unpack command computes exactly the inverse of this mapping.

### Bitwise arithmetic, multiset operations and character transformation


Cmd | Cardinal | Ordinal
--- | -------- | -------
`A` | Pop **y**. Pop **x**. Push the bitwise *AND* of **x** and **y**. | Pop **b**. Pop **a**. Compute the multiset intersection of **a** and **b** (accounting for multiplicities). Specifically, iterate through the characters of **a** and remove the leftmost copy of each character from **b** if it exists, and remove it from **a** otherwise. Concatenate what remains of **a** and **b** and push the result.
`N` | Pop **n**. Push the bitwise *NOT* of **n**. Equivalent to **-n-1**. | Pop **b**. Pop **a**. Compute the multiset complement of **b** in **a** (accounting for multiplicities). Specifically, iterate through the characters of **b** and remove the leftmost copy of each character from **a** if it exists. Push what remains of **a**.
`V` | Pop **y**. Pop **x**. Push the bitwise *OR* of **x** and **y**. | Pop **b**. Pop **a**. Compute the multiset union of **a** and **b** (accounting for multiplicities). Specifically, iterate through the characters of **a** and remove the leftmost copy of each character from **b** if it exists. Concatenate **a** and what remains of **b** and push the result.
`X` | Pop **y**. Pop **x**. Push the bitwise *XOR* of **x** and **y**. | Pop **b**. Pop **a**. Compute the symmetric multiset difference of **a** and **b** (accounting for multiplicities). Specifically, make a copy of **b**, called **b'**, iterate through the characters of **a** and remove the leftmost copy of each character from **b** if it exists. Then iterate through **b'** and remove the leftmost copy of each character from **a** if it exists. Concatenate what remains of **a** and **b** and push the result.
`y` | Pop **z**. Pop **y**. Pop **x**. Push the bitwise if-then-else of **x**, **y** and **z**. Specifically, push **(x AND y) OR (NOT x AND z)**. | Pop **c**. Pop **b**. Pop **a**. Transliterate **a** by mapping **b** to **c** and push the result. The details of this operation are somewhat involved and can be found in the footnote.<sup>‖</sup>
`l` | Pop **n**. Set all of its bits except the most-significant bit to **0**. Push the result. | Pop **s**. Convert letters in **s** to lower case. Whether and how this works for Unicode letters outside the ASCII range, and whether the user's locale is respected is implementation-defined.
`u` | Pop **n**. Set all of its bits except the most-significant bit to **1**. Push the result. | Pop **s**. Convert letters in **s** to upper case. Whether and how this works for Unicode letters outside the ASCII range, and whether the user's locale is respected is implementation-defined.

<sup>‖</sup> Here is how a transliteration is computed. If **c** is empty, remove all copies of the characters in **b** from **a**. Otherwise, repeat **b** often enough so that no character occurs more often in **a** than in **b**. Then repeat **c** often enough so that it is no shorter than **b**. Now create a mapping of each character in **b** to the character in the same position in **c**. Finally, go through the characters in **a**. If the character exists in **b**, replace it with a character from **c** using the leftmost mapping, and then remove that mapping (so that the next copy of this character uses the next mapping and so on). If the character did not exist in **b**, leave it unchanged in **a**. Here is an example: **a = "ABACABADA"**, **b = "ABCA"**, **c = "0123456"**. First, we need to repeat **b** three times so that it contains at least as many **"A"s** as **a**, so we get **b = "ABCAABCAABCA"**. Then we need to repeat **c** twice so that it's at least as long as **b**, so we get **c = "01234560123456"**. This creates the following list of mappings: **[A → 0, B → 1, C → 2, A → 3, A → 4, B → 5, C → 6, A → 0, A → 1, B → 2, C → 3, A → 4]**. Finally, we go through **a** and replace the **i**th occurrence of a character with the **i**th applicable mapping in this list, if it exists. So we end up with **"0132450D1"**. This operation may seem very weird, but it's mostly just a generalisation of several useful character transformation tasks. When both **b** and **c** are the same length, and the characters in **b** are unique, this simply performs a character-by-character transliteration as you might be familiar with from languages like Ruby or sed. To replace digits with their parity, you can use **b = "0123456789"**, **c = "01"**. To fill a string **c** character by character into gaps indicated by underscores in **a**, use **b = "\_"**.

### Number theory and advanced string operations


Cmd | Cardinal | Ordinal
--- | -------- | -------
`B` | Pop **n**. Push all divisors of **n**, in order from smallest to largest. If **n** is negative, all divisors will be pushed negatively as well (still ordered by their absolute magnitude). If **n = 0**, push nothing. | Pop **s**. Push all non-empty contiguous substrings of **s**, from shortest to longest and from left to right.
`D` | Pop **n**. As long as **p<sup>2</sup>** divides **n** for some prime **p**, divide **n** by **p** (that is, remove all "extraneous" copies of prime factors), and push the result. If **n = 0**, push **0**. | Pop **s**. For each character, discard all but its first occurrence in **s**. Push the result.
`F` | Pop **y**. Pop **x**. If **y ≠ 0** and **y** divides **x**, push **y**. Otherwise, push **0**. | Pop **b**. Pop **a**. If **a** contains **b** as a substring, push **b**. Otherwise, push **""**.
`G` | Pop **y**. Pop **x**. Push the greatest common divisor of **x** and **y**. If **x = y = 0**, push **0**. The result is always non-negative. | Pop **b**. Pop **a**. Push the longest substring that occurs in both **a** and **b**. If there are multiple common substrings of the maximal length, each such substring is pushed once (even if it appears multiple times), sorted by its first occurrence in **a**. Note that the empty string is always a common substring of **a** and **b**.
`L` | Pop **y**. Pop **x**. Push the least common multiple of **x** and **y**. The result is always non-negative. | Pop **b**. Pop **a**. Push the shortest possible string which starts with **a** and ends with **b**.
`S` | Pop **z**. Pop **y**. Pop **x**. Determine how often **y** divides **x**, i.e. find the largest **n** for which **y<sup>n</sup>** divides **x**. Divide **x** by **y<sup>n</sup>** and then multiply it by **z<sup>n</sup>**. Push the result. There are several special cases: If **x = 0**, push **0**. If **y = z = ±1**, push **x**. If **y = ±1** and **z = 0**, push **0**. In all other cases, where **y = ±1**, enter an infinite loop. | Pop **c**. Pop **b**. Pop **a**. Replace each non-overlapping occurrence of **b** in **a** with **c**. Push the result.
`c` | Pop **n**. Push the individual prime factors of **n** from smallest to largest (repeating each prime factor as necessary). Special cases: If **n = 0**, push **0**. If **n = 1**, push nothing. If **n < 0** push **-1** followed by the result for **-n**. | Pop **s**. Push the individual characters of **s** separately.
`f` | Pop **n**. Push the prime factors of **n** as pairs of prime and exponent. Special cases: if **n = 0**, push **0, 1**. If **n = 1**, push nothing. If **n < 0**, push **-1, 1** folloewd by the result for **-n**. | Pop **s**. Split **s** between any pair of different adjacent characters (or split **s** into runs of equal characters) and push the individual chunks.
`z` | Pop **y**. Pop **x**. For each prime **p** less than or equal to **y**, divide **x** by **p** as long as possible and push the result. For **y < 0** also uses negative primes **p** so that the sign of **x** is flipped for each removed prime factor. If **x = 0**, push **0**. | Pop **b**. Pop **a**. If **a** contains **b** as a substring, discard everything in **a** up to and including the first occurrence of **b**. Push **a**.

### Combinatorics

Cmd | Cardinal | Ordinal
--- | -------- | -------
`C` | Pop **k**. Pop **n**. Push the binomial coefficient **n-choose-k**. Specifically, if **n > 0** and **k > n/2**, replace **k** with **n-k**. Then if **k < 0**, push **0**. If **k = 0**, push **1**. If **k > 0**, multiply the numbers from **n** down to **n-k+1** and divide them by the numbers from **1** to **k**. | Pop **s**. Push all (not necessarily contiguous) subsequences of **s** from shortest to longest. Each subsequence should be thought of as a subset of the positions in **s** that are retained, while all others are dropped. The order of subsequences for a given length are such that the corresponding lists of retained positions would be canonically ordered.
`P` | Pop **n**. Push **n!**. For negative **n**, multiplies the numbers from **n** up to **-1**, so that we get **(-n)!** for even **n** and **-(-n)!** for odd **n**. | Pop **s**. Push all permutations of **s**, such that if each character was replaced by its index in **s**, the permutations would be canonically ordered. If **s** contains duplicate characters, there will be duplicate permutations.

### Order, randomness and time

Cmd | Cardinal | Ordinal
--- | -------- | -------
`T` | Pop **n**. Sleep for **n** milliseconds. | Push the current date and time in the format **"YYYY-MM-DDTHH:MM:SS.mmm±AA:BB"** where **T** is an actual **"T"** and **±AA:BB** indicates the system's time zone.
`U` | Pop **n**. If **n > 0**, push a uniformly random integer in **[0,n)**. If **n < 0**, push a uniformly random integer in **(n,0]**. If **n = 0**, push **0**. | Pop **s**. Push a character chosen randomly with uniform distribution from **s**. If **s** contains duplicate characters, these will have a higher probability of being drawn. If **s** is the empty string, push the empty string again.
`b` | Pop **y**. Pop **x**. With 50% probability, swap **x** and **y**. Push **x**, push **y**. | Pop **s**. Shuffle **s** with a uniform distribution of possible resulting strings.
`r` | Pop **n**. If **n ≥ 0**, push all integers from **0** to **N**, inclusive. If **n < 0**, push all integers from **-n** to **0**, inclusive. | Range expansion. Pop **s**. First, reduce all consecutive runs of equal characters to a single copy of that character. Then, for each pair of adjacent characters **a** and **b**, insert all intermediate characters between them. Push the result. For example, **"aebbfbbbda"** becomes **"abcdedcbcdefedcbcdcba"**.
`s` | Pop **y**. Pop **x**. If **x > y**, swap **x** and **y**. Push **x**, push **y**. | Pop **s**. Sort the characters in **s**. Push **s**.
`x` | Pop **y**. Pop **x**. Extract the **y**th bit from the binary representation of **x**. | Pop **y**. Pop **x**. Reorder **x** according to **y**, similar to the `,` command. This is done by aligning the strings character-by-character. If **x** is shorter than **y**, the last characters of **y** are paired with empty strings. If **y** is shorter than **x**, the remaining characters in **x** will be unaffected. Then **y** is sorted stably, while keeping each of its characters paired with the corresponding character from **x**. Then join the characters (and possibly empty strings) from **x** back together and push the result. Hence, the characters in **x** are reordered by the same permutation that would sort **y**.
