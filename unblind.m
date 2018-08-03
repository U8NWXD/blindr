% blindr: A program for reversibly randomizing filenames
% Copyright (C) 2018  U8N WXD

% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU Affero General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Affero General Public License for more details.

% You should have received a copy of the GNU Affero General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

disp('blindr  Copyright (C) 2018  U8N WXD')
disp('This program comes with ABSOLUTELY NO WARRANTY.')
disp('This is free software, and you are welcome to redistribute it')
disp('under certain conditions.')
disp('')

% Constants
KEY = 'blindingKey.csv';    % Filename of key file
VERSION = 'version.txt'; % Filename of version file
% Potentially appended to end of blinded name to create log name
% Must be a cell array of strings with all column indices = 1
% and row indices 1 ... N for N suffixes
LOG_SUFFIXES = [cellstr('_CS.txt'); cellstr('_CS')];
LOG_PREFIX = 'log';
USE_JAVA = ispc;          % Whether or not to use Java for renaming files
VERSION_CUR = [1 0 0];

% Import Statements
if USE_JAVA
  import java.io.File;
end;

function f = semantic_compatible(current, file)
  if current(1) == file(1)
    if current(2) >= file(2)
      f = true;
    else
      f = false;
    end
  else
    f = false;
  end
end

% Check that there is a version file present and that versions are compatible
if exist(VERSION, 'file') == 2
  file = fopen(VERSION, 'rt');
  vers = textscan(file, '%d %d %d', 'Delimiter', ',');
  found = [vers{1,1} vers{1,2} vers{1,3}];
  if ~ semantic_compatible(VERSION_CUR, found)
    disp('Blinding was performed by an unsupported version of blindr. Aborting.');
    disp('Current Version:');
    disp(VERSION_CUR);
    disp('Version that Performed Blinding:')
    disp(found);
    return;
  end;
else
  disp('No version file found. Aborting.')
  return;
end;

% Check that there is a key file present
if exist(KEY, 'file') ~= 2
  disp('No key file found. Aborting.');
  return;
end;

% Read in blinding key from key file
file = fopen(KEY);
all = textscan(file, '%s %s', 'Delimiter', ',');
fclose(file);

% Extract original and blinded names from blinding key
original_names = all{1,1};
blinded_names = all{1,2};

% Unblind files
for k = 1:numel(original_names)
  blind = blinded_names{k, 1};
  origi = original_names{k, 1};

  disp(strcat('Renaming "', blind, '" to "', origi, '"'))

  if exist(blind, 'file') ~= 2
    disp(strcat('The file "', blind, '" is missing. Skipping.'))
  elseif exist(origi, 'file') == 2
    disp(strcat('The file "', origi, '" already exists. Skipping.'))
  else
    if USE_JAVA
      old = java.io.File(blind);
      new = java.io.File(origi);
      old.renameTo(new);
    else
      movefile(blind, origi);
    end;
    if exist(origi, 'file') ~= 2
      disp(strcat('Renaming "', blind, '" to "', origi, '" failed. Aborting.'));
      return;
    end;
  end;

  % Unblind any log files found
  for i = 1:numel(LOG_SUFFIXES)
    suffix = LOG_SUFFIXES{i,1};
    log = strcat(LOG_PREFIX, blind, suffix);
    unBlindLog = strcat(origi, suffix);
    if exist(log, 'file') == 2
      disp(strcat('Renaming "', log, '" to "', unBlindLog, '"'))
      if exist(unBlindLog, 'file') == 2
        disp(strcat('The file "', unBlindLog, '" already exists. Skipping.'))
      else
        if USE_JAVA
          old = java.io.File(log);
          new = java.io.File(unBlindLog);
          old.renameTo(new);
        else
          movefile(log, unBlindLog);
        end;
        if exist(unBlindLog, 'file') ~= 2
          disp(strcat('Renaming "', log, '" to "', unBlindLog, '" failed. Aborting.'));
          return;
        end;
      end;
    end;
  end;
end;
