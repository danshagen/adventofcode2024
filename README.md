# Advent of Code 2024

This is my first attempt at the [Advent of Code](https://adventofcode.com/).
I am trying to solve it with a new programming language and chose [Zig](https://ziglang.org/).

My resources for learning Zig:

 - [Zig Language Reference](https://ziglang.org/documentation/master/)
 - [Zig Standard Library](https://ziglang.org/documentation/master/std/#)
 - [Advent of Code in Zig](https://kristoff.it/blog/advent-of-code-zig/)

## Running the puzzles

The input files are not put into the repo and are git ignored (`input.txt`).
They are loaded into the programs via `@embedFile("input.txt")` and are expected to sit in the same directory as the files.
I usually develop with tests first, so I run

```
zig test day01/day01-01-zig
```

for tests and

```
zig run day01/day01-01-zig
```

to get the puzzle results.
My code editor, Sublime Text, runs those commands automatically with the Zig language package.
This makes development quite straightforward.
