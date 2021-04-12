# Cella Installation Notes

## Important Notes:

The installer does not make permanent changes to the environment. 
If you want `cella` in the PATH for new shell sessions, you will 
have to add it to your profile manually. See [AutoLoad Cella](#autoload-cella) below

## Installation

You can install `cella` with one of the following commands:

Posix: (Linux,OSX,FreeBSD)
  - `. <(curl aka.ms/cella.sh -L )` or 
  - `. <(wget aka.ms/cella.sh -q -O -)`
  
  - if those don't work well, try bringing the file local and dot-sourcing it.  
    `wget aka.ms/cella.sh -q && . ./cella.sh --debug --reset-cella` 
    
PowerShell/pwsh: 
  - `iex (iwr -useb aka.ms/cella.ps1)` 
  
Windows CMD.exe:
  - `curl -L aka.ms/cella.cmd -o cella.cmd && cella.cmd`

Install as a NPM package:
  - `npm install -g https://aka.ms/cella.tgz`


## Running cella in a new window:

`cella`'s installer does not update the user's profile or persist any environment changes
which means that it won't be loaded when you open a new console.

You can just run the cella script and it will add itself into the current environment

Posix: (Linux,OSX,FreeBSD)
  - `. ~/.cella/cella` 
 
PowerShell/pwsh: 
  - `. $HOME/.cella/cella.ps1`  -- Windows PowerShell or `pwsh`
  - `~/.cella/cella.ps1`  -- Only on `pwsh` (PowerShell 6+)
  
Windows CMD.exe:
  - `%USERPROFILE%\.cella\cella.cmd`

If installed as an NPM package:
  - On Windows, you can just call `cella` on the command line, on Posix, you have to dot-source it first `. cella`


## Autoload cella

You can add the command to load cella into your profile (ie, .bash_rc, powershell profile, etc )


Posix: (Linux,OSX,FreeBSD)
  - `echo ". ~/.cella/cella" >> ~/.bash_rc `  -- or whatever shell profile you have.
 
PowerShell/pwsh: 
  - `echo "$HOME/.cella/cella.ps1" >> $PROFILE` 
  
Windows CMD.exe or powershell:
  - Since you can run `cella.cmd` or `cella.ps1` from the command line, you can also
    just edit your `PATH` in the environment variables system util.


## Updating Cella

At the moment, the simple way to update `cella` to the latest build is to use `cella --reset-cella` to 
force the latest build to get installed. 

## Cella Command line

use `cella help` to get the command line help


