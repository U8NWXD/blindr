% Constants
KEY = 'blindingKey.csv';    % Filename of key file
% Potentially appended to end of blinded name to create log name
% Must be a cell array of strings with all column indices = 1
% and row indices 1 ... N for N suffixes
LOG_SUFFIXES = [cellstr('_CS.txt'); cellstr('_CS')];

% Read in blinding key from key file
file = fopen(KEY);
all = textscan(file, '%s %s', 'Delimiter', ', ');
fclose(file);

% Extract original and blinded names from blinding key
original_names = all{1,1};
blinded_names = all{1,2};

% Unblind files
for k = 1:numel(original_names)
  blind = blinded_names{k, 1};
  origi = original_names{k, 1};

  strcat('Renaming "', blind, '" to "', origi, '"')

  if exist(blind, 'file') ~= 2
    strcat('The file "', blind, '" is missing. Skipping.')
  elseif exist(origi, 'file') == 2
    strcat('The file "', origi, '" already exists. Aborting.')
    all
    quit;
  else
    movefile(blind, origi);
  end;

  % Unblind any log files found
  for i = 1:numel(LOG_SUFFIXES)
    suffix = LOG_SUFFIXES{i,1};
    log = strcat(blind, suffix);
    unBlindLog = strcat(origi, suffix);
    if exist(log, 'file') == 2
      strcat('Renaming "', log, '" to "', unBlindLog, '"')
      if exist(unBlindLog, 'file') == 2
        strcat('The file "', unBlindLog, '" already exists. Skipping.')
      else
        movefile(log, unBlindLog);
      end;
    end;
  end;
end;
