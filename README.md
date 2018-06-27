# `blindr`: Reversibly Randomizing Filenames

Consider trying to analyze data you have collected for your scientific research.
If the names of the data-files reveal their source, your analysis could be
biased by your expectations of which sources should show which results. Blinding
the data, hiding identifying information from the analyzer, is one way to
mitigate this kind of bias.

With many data files, however, manually renaming them and keeping track of which
"blinded" name is related to which original name is both a waste of time and
error-prone. This program automates both blinding and un-blinding files, and it
includes safeguards against destroying any information in the process.

## Compatibility

The scripts are written to be compatible with both MATLAB and Octave, with some
caveats. `movefile` is extremely slow with large files on Windows operating
systems, so Java's `renameTo` method is used instead for Windows. However,
Octave does not support importing Java functions, so on Windows, MATLAB is
required. All other parts of the scripts should work with both MATLAB and
Octave, though you should run tests simulating your production environment
before use.

## Suggested Workflow

This is a potential workflow for the analysis of scientific data.
* Copy `blind.m` to directory of files to blind
* Set the `EXTENSION` constant in `blind.m` as dictated by the type of file
  to blind
* Run `blind.m`
* Check the console output for any errors
* Copy the console output to a text file
* Delete `blind.m`
* Move the console output file and `blindingKey.csv` to a trusted location
  inaccessible to the researcher who will do the analysis
* Create a dummy `blindingKey.csv` file to prevent accidental blinding
* Process the data as you normally would, using the blinded names in place of
  the actual ones. Store results as `log[blinded name]_[initials].txt`
* Copy `unblind.m` and `blindingKey.csv` back into the directory
* Replace `CS` in `LOG_SUFFIXES` in `unblind.m` with the initials in the log
  files
* Run `unblind.m`
* Check the output for errors and skips
* Process your results as normal using the now-revealed original file names

## Normal Operation

### Blinding
All files matching `*.[EXTENSION]`, where `[EXTENSION]` is the value of the
constant `EXTENSION` in `blind.m`, are renamed to a unique, random integer in
the set `[1, N]`, where `N` is the number of files renamed. This means that
after blinding, the renamed files will be numbered sequentially from `1` to `N`
in a random order and in the form `[i].[EXT]` where `[EXT]` is the
original file extension (equal to the value of `EXTENSION`) and `[i]` is the
sequential number.

Upon blinding, in the same directory as the blinded files, a file
`blindingKey.csv` is created. This file complies with the CSV format and stores
the original file names in its first column and the blinded file names in its
second column. This file is needed by `unblind.m` to reveal the original names.
For example:

| Column 1          | Column 2|
|-------------------|---------|
| originalName1.txt | 3.txt   |
| originalName2.txt | 1.txt   |
| originalName3.txt | 2.txt   |


### Unblinding
All files found in the second column of `blindingKey.csv` are renamed to the
entry in the first column of the same row. From the example table above, `3.txt`
would be renamed to `originalName1.txt`. In addition, log files whose names
comply with the format `[PREFIX][blinded_name][SUFFIX]`, where `[PREFIX]` is
the string stored in the `PREFIX` constant in `unblind.m` and `[SUFFIX]` is one
of the strings stored in the `LOG_SUFFIXES` cell array in `unblind.m`, are
unblinded. For example, with `PREFIX` equal to `log` and `LOG_SUFFIXES`
containing `_CS` and `_CS.txt`, the valid log files for `3.txt` would be
`log3.txt_CS` and `log3.txt_CS.txt`.

## Safeguards Against Data Loss

### Overwriting Data Files With Renaming
Under the hood, file renaming is often actually moving a file to a file in the
same directory with a different name. This means that if the new name
(destination file) already exists, the existing file can be lost. To prevent
this, `blind.m` checks before performing any blinding that none of the blinded
names it will use are already in use in the current directory. Further, both
`blind.m` and `unblind.m` check just before renaming files that the new name is
not already in use. If a new name is already in use, `blind.m` prints an error
message and aborts, while `unblind.m` skips that file. This difference in
behavior stems from the fact that `unblind.m` can be re-run to un-blind skipped
files, while re-running `blind.m` on a subset of files would create name
conflicts (e.g. multiple `1.txt` files).

### Overwriting Blinding Keys
`blind.m` aborts before performing any blinding if `blindingKey.csv` already
exists. This also occurs before any data is written to `blindingKey.csv`, so
the blinding keys from a previous run cannot be overwritten unless the file
is renamed. **NEVER RENAME THE BLINDING KEY FILE!**

### Altering File Contents
Data files are only renamed; their contents are never altered. The only commands
used that could alter files are those used to write to `blindingKey.csv`, and
they are only ever applied to that specific file. See the section
`Overwriting Blinding Keys` to see why this cannot alter file contents.

### Re-Blinding Blinded Files
Since `blind.m` refuses to blind a directory that already contains
`blindingKey.csv`, it will not blind a directory that has just been blinded.
This helps stop the user from accidentally blinding twice. However, one is
likely to move `blindingKey.csv` elsewhere. **If you move the blinding key file,
create another CSV with the same name to prevent accidental blinding.** In
addition, as soon as you finish blinding, delete `blind.m` and `unblind.m` to
make it harder to accidentally re-blind files.

### Partial Blinds From Mid-Execution Failures
Both `blind.m` and `unblind.m` print to the console status updates with every
file renaming. These updates include both the old and new names, making manual
reversal of all name changes possible. A prudent step might be to copy the
console output from each execution and store it with `blindingKey.csv` as a
last-resort option for data recovery.

Furthermore, `blind.m` creates the full blindings key file before starting any
blindings. If the script fails in the middle of blinding, `blindingKey.csv` will
already exist, so `unblind.m` should be able to reverse the blinding. Some files
may not yet have been blinded, but `unblind.m` will simply skip over them.

### Unexpected Behavior
When renaming files, `blind.m` and `unblind.m` also check that the new file
exists after renaming has completed. If it does not, such as if the filesystem
is read-only, they abort with an error message. This helps assure that the
scripts behave exactly as expected.

`blind.m` aborts if a file it intended to rename goes missing. This means that
a file that was present at the beginning of execution has disappeared as the
program ran. This might mean that some other process is modifying the directory
or that the file had somehow already been blinded, but `blind.m` interprets both
as anomalous and aborts with an error message.

## Additional Documentation
If any blinded files are missing, `unblind.m` will simply skip over them while
printing a notice. This is because it can be re-run later, unlike `blind.m`.
If any log files are missing, `unblind.m` silently skips them because log files
are considered to be potentially present, but not necessarily so.

Instead of the `quit` command, mid-execution stops are achieved using `return`.
This avoids quitting the MATLAB program, if it is used, so the console outputs
will remain visible for diagnostics.

## Copyright and License
blindr: A program for reversibly randomizing filenames
Copyright (C) 2018  U8N WXD

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
