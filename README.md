# sokol-zig-examples

Some of the Sokol examples running in Zig 0.15.1 (August 2025). Intended to be used as a reference or starting point for anyone looking to use Zig make games. Working platforms:
 - Windows (OpenGL)
 - Web (GLES3)
 - MacOS (OpenGL) [Not recently tested, may not work]
 
With some modifications to the build.zig script it could be modified to target other platforms.

See
   - https://github.com/floooh/sokol
   - https://github.com/floooh/sokol-samples
   - https://github.com/floooh/sokol-zig
   - https://github.com/ziglang/zig

## Building

Clone

    git clone --recurse-submodules https://github.com/jeffkdev/sokol-zig-examples.git
    
    
Navigate to the root directory and run application using:

    zig build run

This will build all examples and run the first valid example defined
   
To build and run a specific example use the `-Dmain=` argument:
```
zig build -Dmain=example_cube run
zig build -Dmain=example_imgui run
zig build -Dmain=example_instancing run
zig build -Dmain=example_sound run
zig build -Dmain=example_triangle run
```
This will skip building any other examples

Use the standard release options to specify mode. Ex:
`zig build -Dmain=example_cube -Doptimize=ReleaseFast run`


valid files are:
  example_imgui.zig
![example_imgui.zig](docs/imgui.png)
  
  example_instancing.zig
![example_instancing.zig](docs/instancing.png)

  example_cube.zig
![example_cube.zig](docs/cube.png)
  
  example_triangle.zig
![example_triangle.zig](docs/triangle.png)

  example_sound.zig
(plays beeping sound, blank screen)

## WASM
Can run specific example:
```
zig build -Dtarget=wasm32-emscripten -Dmain=example_instancing run
```

Note: example_sound requires clicking in the window anywhere before the application is allowed to play sound.

This repo shows how to support web assembly builds using the sokol c code directly without the sokol Zig wrapper. The code was migrated from https://github.com/floooh/sokol-zig. See the source repo for more details. It will download the emscripten version defined in build.zig.zon automatically so the first compile will take longer.
## Shaders

The "glsl.h" shader files are generates from the ".glsl" files using. [sokol-shdc](https://github.com/floooh/sokol-tools). Since the glsl.h files are not created automatically when building right now they are checked in as well. If you modify the files, they can be re-generated using the command:

```
sokol-shdc.exe --input cube.glsl --output cube.glsl.h --slang glsl430:metal_macos:hlsl5:glsl300es:wgsl --format sokol_impl
```
A python file build_shaders.py is included for convenience that will create the required glsl.h files and the *_compile.c files which calls the above command for each listed file (requires sokol-shdc.exe in the environment paths).

The "--format sokol_impl" is important, otherwise they will be generated with inline declarations which caused issues using them in Zig. See the [documentation](https://github.com/floooh/sokol-tools/blob/master/docs/sokol-shdc.md) for more command line references.

## Debugging


Debugging and breakpoints are working in Visual Studio Code. Run and Debug (F5) will prompt for a file to run and build. 
## License

Example files are based on the sokol-examples so they are probably considered a derivate work, so the MIT license will carry on to those as well.
