function rootPath = rootPath()
% Determine path to root of the mrVista directory
%
%        rootPath = vistaRootPath;
%
% This function MUST reside in the directory at the base of the
% afqDimensionality directory structure 
%
% Copyright Stanford team, mrVista, 2018

rootPath = which('rootPath');

rootPath = fileparts(rootPath);

return
