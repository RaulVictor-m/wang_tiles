# Wang tile Visualizer

This is a very basic wang tile visualizer that makes use of the ppm format to generate an image for its output

It currently only has a single shape of tiles which is triangles like these examples in: https://en.wikipedia.org/wiki/Wang_tile

## Objective 

The main objective of this repo is exploring the use of zigs builtin Vector and also explore a little on [tsoding's idea](https://www.youtube.com/watch?v=IGTuv_KKLFs&list=PLpM-Dvs8t0VYgJXZyQzWjfYUm3MxcvqR0) for wang tiles.

## Usage 

There is nothing fancy built in to this, so if you want to see what it does you just need to compile with default zig build:

```console
$ zig build run
```

With this you will see a output.ppm file with your result.

if you need any help on the options or optimizations just use zig build help menu:

```console
$ zig build --help
```

