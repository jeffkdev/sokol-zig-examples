# sokol-zig-examples

Some of the Sokol examples running in Zig. Intended to be used as a reference or starting point for anyone looking to use Zig make games. Only working in Windows at the moment, but with some effort could be modified to target other platforms.

See
   - https://github.com/floooh/sokol
   - https://github.com/floooh/sokol-samples
   - https://github.com/ziglang/zig
    
If you are visiting this page in the future you may want to check the status of this repo by the creator of Sokol, which may or may not be more developed:
  -  https://github.com/floooh/sokol-zig


## Building

Clone

    git clone --recurse-submodules https://github.com/jeffkdev/sokol-zig-examples.git

Download and add zig.exe to path (see zig link above)
    
Build imgui .o files (clang++ required. One time only)

    build.bat
    
    
Run application in the future using:

    zig build run
    
   
A bit hacky, but to run different examples change the main file in the build.zig file:
    const mainFile = "example_imgui.zig"; 

valid files are:
  example_imgui.zig
![example_imgui.zig](docs/imgui.png)
  
  example_cube.zig
![example_cube.zig](docs/cube.png)
  
  example_triangle.zig
![example_triangle.zig](docs/triangle.png)
  
  example_sound.zig
  
(plays beeping sound, blank screen)
  

## Debugging

Debugging and breakpoints are working in Visual Studio Code. Ideally there would be a launch config for each example, but right now it just runs the program.exe that is created from the zig build. Two files are required in the .vscode folder (not included in repo):

### tasks.json
```
  {
    "tasks":[
     {
      "group":"build",
      "problemMatcher":[
       "$msCompile"
      ],
      "command":"zig build",
      "label":"zig_build"
     },
    ],
    "presentation":{
     "reveal":"always",
     "clear":true
    },
    "version":"2.0.0",
    "type":"shell"
   }
 ```
### launch.json
```
{
  "version":"0.2.0",
  "configurations":[
   {
    "environment":[],
    "stopAtEntry":false,
    "program":"${workspaceRoot}/zig-cache/bin/program.exe",
    "name":"program",
    "externalConsole":false,
    "preLaunchTask":"zig_build",
    "request":"launch",
    "args":[],
    "type":"cppvsdbg",
    "cwd":"${workspaceRoot}"
   }
  ]
 }
 ```
## License

Example files are based on the sokol-examples so they are probably considered a derivate work, so the MIT license will carry on to those as well.
