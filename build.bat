echo off
cd build
..\bin\oc /B Buildfile /sym "..\source"
cd ..
echo on
