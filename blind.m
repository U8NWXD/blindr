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
EXTENSION = 'avi';
USE_JAVA = ispc;

% Import Statements
if USE_JAVA
  import java.io.File;
end;

% Check that there is no key file present
if exist('blindingKey.csv', 'file') == 2
  disp('A blindingKey.csv file already exists. Aborting.');
  return;
end;

% Read Existing Filenames and Compute Blinded Names
directory  = dir(strcat('*.', EXTENSION));
old_names = {directory.name};
new_names = randperm(numel(old_names));
new_names = num2cell(new_names);

% Create Key for Unblinding And Save to blindingKey.csv
key = [transpose(old_names), transpose(new_names)];
file = fopen('blindingKey.csv', 'w') ;
for row = 1:numel(old_names)
    fprintf(file,'%s, %d.avi\r\n', key{row,:});
end;
fclose(file);

% Ensure none of the blinded names are already used
for k = 1:numel(new_names)
  new_name = strcat(int2str(new_names{k}), '.', EXTENSION);
  if exist(new_name, 'file') == 2
    disp(strcat('The file "', new_name, '" already exists. Aborting.'))
    return;
  end;
end;

% Blind files
for k = 1:numel(old_names)
  old_name = old_names{k};
  new_name = strcat(int2str(new_names{k}), '.', EXTENSION);
  disp(strcat('Renaming "', old_name, '" to "', new_name, '"'))

  if exist(old_name, 'file') ~= 2
    disp(strcat('The file "', old_name, '" appears to have disappeared. Aborting.'))
    return;
  elseif exist(new_name, 'file') == 2
    disp(strcat('The file "', new_name, '" already exists. Aborting.'))
    return;
  else
    if USE_JAVA
      old = java.io.File(old_name);
      new = java.io.File(new_name);
      old.renameTo(new);
    else
      movefile(old_name, new_name);
    end;
    if exist(new_name, 'file') ~= 2
      disp(strcat('Renaming "', old_name, '" to "', new_name, '" failed. Aborting.'));
      return;
    end;
  end;
end;
