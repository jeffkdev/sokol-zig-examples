REM Note: Only need to run once to build imgui. Use "zig build" or "zig build run" for future builds
@echo off
pushd ..\build\
clang++ -c -g -gcodeview -Wno-deprecated-declarations -Wno-return-type-c-linkage ..\src\cimgui\imgui\imgui.cpp -I ..\src\cimgui -o imgui.obj
clang++ -c -g -gcodeview -Wno-deprecated-declarations -Wno-return-type-c-linkage ..\src\cimgui\imgui\imgui_demo.cpp -I ..\src\cimgui -o imgui_demo.obj
clang++ -c -g -gcodeview -Wno-deprecated-declarations -Wno-return-type-c-linkage ..\src\cimgui\imgui\imgui_draw.cpp -I ..\src\cimgui -o imgui_draw.obj
clang++ -c -g -gcodeview -Wno-deprecated-declarations -Wno-return-type-c-linkage ..\src\cimgui\imgui\imgui_widgets.cpp -I ..\src\cimgui -o imgui_widgets.obj
clang++ -c -g -gcodeview -Wno-deprecated-declarations -Wno-return-type-c-linkage ..\src\cimgui\cimgui.cpp -I ..\src\cimgui -o cimgui.obj
popd
REM make sure you have zig.exe on your classpath
zig.exe build run
