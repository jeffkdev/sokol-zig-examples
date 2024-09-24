# sokol-zig-examples

Some of the Sokol examples running in Zig 0.13.0 (June 2024). Intended to be used as a reference or starting point for anyone looking to use Zig make games. Working platforms:
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
    
   
To run different examples change the main file in the build.zig file:
```    const main_file = "example_instancing.zig"; ```

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
All examples should work in the web browser using:
```
zig build -Dtarget=wasm32-emscripten run
```

This repo shows how to support web assembly builds using the sokol c code directly without the zig wrapper. The code was migrated from https://github.com/floooh/sokol-zig. See the source repo for more details. It will download the emscripten version defined in build.zig.zon automatically so the first compile will take longer.

# WASM multi-threading

A multi-threading example is not yet included in this repo, but if you want to support multi-threading you should be able to get it working by adding additional arguments to th emLinkStep:
```zig
        // Required for LTO while bug exists: https://github.com/emscripten-core/emscripten/issues/16836
        "-Wl,-u,_emscripten_run_callback_on_thread",
        "-pthread",
        "-satomics=1",
        // Set to whatever pool size
        "-sPTHREAD_POOL_SIZE=8",
        // -pthread + ALLOW_MEMORY_GROWTH may run non-wasm code slowly, see https://github.com/WebAssembly/design/issues/1271
        "-Wpthreads-mem-growth", 
```

If you are using the standard thread pool (Pool.zig) in Zig 0.13.0 it will give you an error using `std.Thread.getCpuCount()` on WASM. You can work around this by checking if `@import("builtin").target.isWasm()` and providing an explicit thread pool count and then compiling in release mode so it will be compiled away.
```zig
const thread_count = options.n_jobs orelse @max(1, std.Thread.getCpuCount() catch 1);
```

Then when you compile include atomics in the zig build CPU arguments: `zig build -Dtarget=wasm32-emscripten -Dcpu=bleeding_edge+atomics run`

Also if your game to itch.io you will need to enable  the `SharedArrayBuffer support` option

## Shaders

The "glsl.h" shader files are generates from the ".glsl" files using. [sokol-shdc](https://github.com/floooh/sokol-tools). Since the glsl.h files are not created automatically when building right now they are checked in as well. If you modify the files, they can be re-generated using the command:

```
sokol-shdc.exe --input cube.glsl --output cube.glsl.h --slang glsl430:metal_macos:hlsl5:glsl300es:wgsl --format sokol_impl
```
A python file build_shaders.py is included for convenience that will create the required glsl.h files and the *_compile.c files which calls the above command for each listed file (requires sokol-shdc.exe in the environment paths).

The "--format sokol_impl" is important, otherwise they will be generated with inline declarations which caused issues using them in Zig. See the [documentation](https://github.com/floooh/sokol-tools/blob/master/docs/sokol-shdc.md) for more command line references.

## Debugging

Debugging and breakpoints are working in Visual Studio Code. Ideally there would be a launch config for each example, but right now it just runs the program.exe that is created from the zig build. Two files are required in the .vscode folder (not included in repo):

### tasks.json
```
{
    "tasks": [
        {
            "group": "build",
            "problemMatcher": [
                "$msCompile"
            ],
            "command": "zig build",
            "label": "zig_build",
            "options": {
                "cwd": "${workspaceRoot}"
            },
        },
    ],
    "presentation": {
        "reveal": "always",
        "clear": true
    },
    "version": "2.0.0",
    "type": "shell"
}
 ```
### launch.json
```
{
    "version": "0.2.0",
    "configurations": [
        {
            "environment": [],
            "stopAtEntry": false,
            "program": "${workspaceRoot}/zig-out/bin/program.exe",
            "name": "program",
            "console": "integratedTerminal",
            "preLaunchTask": "zig_build",
            "request": "launch",
            "args": [],
            "type": "cppvsdbg",
            "cwd": "${workspaceRoot}"
        }
    ]
}
 ```
## License

Example files are based on the sokol-examples so they are probably considered a derivate work, so the MIT license will carry on to those as well.
