echo off
cd test
..\bin\oc /B Buildfile /sym ..\source
cd ..
echo on
copy bin\Patchouli.BigNums.dll test\
copy bin\Oberon07.*.dll test\
