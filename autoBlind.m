% Constants
EXTENSION = 'avi';

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
    strcat('The file "', new_name, '" already exists. Aborting.')
    quit;
  end;
end;

% Blind files
for k = 1:numel(old_names)
  old_name = old_names{k};
  new_name = strcat(int2str(new_names{k}), '.', EXTENSION);
  strcat('Renaming "', old_name, '" to "', new_name, '"')

  if exist(old_name, 'file') ~= 2
    strcat('The file "', old_name, '" appears to have disappeared. Aborting.')
    quit;
  elseif exist(new_name, 'file') == 2
    strcat('The file "', new_name, '" already exists. Aborting.')
    quit;
  else
    movefile(old_name, new_name);
  end;
end;
