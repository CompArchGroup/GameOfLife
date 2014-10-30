Game of Life (now in MIPS!)
===========================
This is the final project in Computer Architecture of Andrew, Corrin, Eric, and
Ian. It uses the awesome power of MIPS assembly to play the Game of Life for
you.

Some things to keep in mind throughout the program:
* We are reserving register `$s5` for the width of lines.
* We are reserving register `$s6` for the first address of the grid.
* We are reserving register `$s7` for the last address of the grid.

Also, note the style of the internal labels: 2 spaces indent, with a prefix
denoting the subroutine it is in. This makes it clear that everything indented
is all one subroutine. It also helps prevent name conflicts between team
members.
