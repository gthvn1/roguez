# RogueZ

A simple roguelike game written in Zig.

- Tested with Zig 0.15.2
- We are using *ncurses* for displaying output.
On some distributions, the *libncurses.so* library is provided as a linker script rather
than a regular ELF file. It seems that Zig does not handle this correctly, so we build
*ncurses* manually as follows:
- From the project root, create and enter a directory for *ncurses*:
```sh
mkdir ncurses
cd ncurses
```
- Download and extract the source from *ncurses*'[homepage](https://invisible-island.net/datafiles/release/ncurses.tar.gz)

```sh
wget https://ftp.gnu.org/gnu/ncurses/ncurses-6.5.tar.gz
tar xf ncurses.tar.gz
cd ncurses-6.5
```
- Build and install *ncurses* locally. Linux distributions handle multilib
(multi-architecture) systems differently. For example, Debian installs 64-bit
libraries under `/usr/lib`, while OpenSuse uses `/usr/lib64`.

- We also see some differences in how the boolean type is defined. On some systems
it relies on `<stdbool.h>` (usin the C99 *bool* type), while on others it falls back to
an interger type. This leads to ABI incompatibilites when building ncurses with Zig:
on our Debian distribution *bool* maps to *bool*, while on OpenSuse it maps to *c_int*.
We didn't find how to handle it. Currently it is tested on Debian and you need to change
the type in examples if you have this issue.
```sh
./configure \
    --without-ada \
    --libdir="$PWD/../lib64" \
    --prefix="$PWD/../"
make
make install
```
- You should now have *ncurses* installed locally.
- Run the project with:
```sh
zig build run
```

## Main files

### Entry point
- `src/main.zig`: entry point and game loop

### Core game logic
- `src/board.zig`: static parts of the world (walls, floors, flag, ...) called *tiles*
- `src/game.zig`: core game logic (collisions, movement, viewport, ...)
- `src/state.zig`: dynamic elements (robot, boxes, keys, doors, ...) called *items*

### Supported structures
- `src/map.zig`: contains the map as a string

*Note: "tiles" are static parts of the world that cannot be interacted with. "Items" are objects that can move or be interacted with, even if they don't move.*

# Roadmap

- [x] Move robot around an empty map
- [x] Create and display a board
- [x] Add doors to the board
- [x] Add keys to open doors
- [x] Allow moving one box to an empty space
  - *To do*: allow moving several boxes at once
- [x] Retrieve a key
  - *To do*: Put down the key
  - *To do*: If we cannot pick up the key we should be able to move over it
- [x] Open door with the corresponding key
- [x] Add an end when the flag is captured
- [ ] Improve display using *ncurses*
  - [x] Begin with C and transition to Zig: `zigging-with-ncurses`
  - [ ] Swap out the current text-based implementation
- [ ] Implement a viewport for larger worlds
- [ ] Add bombs, enemies, ...

# Screenshots

![First steps](screenshot.png "first steps")
