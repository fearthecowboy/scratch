#!/bin/sh

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# wrapper script for ce.
# this is intended to be dot-sourced and then you can use the ce() function.

# DEBUGGING :
# set | grep -i ^VCPKG

# check to see if we've been dot-sourced (should work for most POSIX shells)
sourced=0

if [ -n "$ZSH_EVAL_CONTEXT" ]; then
  case $ZSH_EVAL_CONTEXT in *:file) sourced=1;; esac
elif [ -n "$KSH_VERSION" ]; then
  [ "$(cd $(dirname -- $0) && pwd -P)/$(basename -- $0)" != "$(cd $(dirname -- ${.sh.file}) && pwd -P)/$(basename -- ${.sh.file})" ] && sourced=1
elif [ -n "$BASH_VERSION" ]; then
  (return 0 2>/dev/null) && sourced=1
else # All other shells: examine $0 for known shell binary filenames
  # Detects `sh` and `dash`; add additional shell filenames as needed.
  case ${0##*/} in sh|dash) sourced=1;; esac
fi

if [ $sourced -eq 0 ]; then
  echo 'This script is expected to be dot-sourced so that it may load ce into the'
  echo 'current environment and not require permanent changes to the system when you activate.'
  echo ''
  echo "You should instead run '. $(basename $0)' first to import ce into the current session."
  exit
fi

# GLOBALS
VCPKG_NODE_LATEST=16.12.0
VCPKG_NODE_REMOTE=https://nodejs.org/dist/
VCPKG_PWD=`pwd`

VCPKG_init() {
  VCPKG_OS="$(uname | sed 'y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/')"
  VCPKG_ARCH="$(uname -m | sed -e 's/x86_64/x64/;s/i86pc/x64/;s/i686/x86/;s/aarch64/arm64/')"

  case $VCPKG_OS in
    ( mingw64_nt* | msys_nt* ) VCPKG_OS="win";;
    ( darwin*|*bsd*) VCPKG_IS_THIS_BSD=TRUE;;
    ( aix ) VCPKG_ARCH="ppc64" ;;
  esac

  if [ ! -z "$VCPKG_IS_THIS_BSD" ]; then
    VCPKG_START_TIME=$(date +%s)
  else
    VCPKG_START_TIME=$(($(date +%s%N)/1000000))
  fi

  # find important cmdline args
  VCPKG_ARGS=()
  for each in "$@"; do case $each in
    --reset-ce) VCPKG_RESET=TRUE;;
    --remove-ce) VCPKG_REMOVE=TRUE;;
    --debug) VCPKG_DEBUG=TRUE && VCPKG_ARGS+=("$each");;
    *) VCPKG_ARGS+=("$each");;
  esac ;done
}

VCPKG_RESET=TRUE

VCPKG_init "$@"
shift $#

# at this point, we're pretty sure we've been dot-sourced
# Try to locate the $VCPKG_ROOT folder, where the ce is installed.
if [ -n "$VCPKG_ROOT" ]; then
  # specify it on the command line if you like, we'll export it
  export VCPKG_ROOT=$VCPKG_ROOT
else
  # default is off the home folder
  export VCPKG_ROOT=~/.vcpkg
fi;

CE=${VCPKG_ROOT}
mkdir -p $CE

VCPKG_DOWNLOADS=${CE}/downloads

VCPKG_NODE=${CE}/downloads/bin/node
VCPKG_NPM=${CE}/bin/npm

VCPKG_debug() {
  if [ ! -z "$VCPKG_IS_THIS_BSD" ]; then
    local NOW=$(date +%s)
    local OFFSET="$(( $NOW - $VCPKG_START_TIME )) sec"
  else
    local NOW=$(($(date +%s%N)/1000000))
    local OFFSET="$(( $NOW - $VCPKG_START_TIME )) msec"
  fi

  if [ ! -z "$VCPKG_DEBUG" ]; then
    if [ -n "$VCPKG_NESTED" ]; then
      echo "[NESTED $OFFSET] $*"
    else
      echo "[$OFFSET] $*"
    fi
  fi

  if [ -n "$VCPKG_NESTED" ]; then
    echo "[NESTED $OFFSET] $*" >> $VCPKG_ROOT/log.txt
  else
    echo "[$OFFSET] $*" >> $VCPKG_ROOT/log.txt
  fi
}

if [ ! -z "$VCPKG_RESET" ]; then
  if [ -d $CE/node_modules ]; then
    echo Forcing reinstall of vcpkg-ce package
    rm -rf $CE/node_modules
  fi

  if [ -d $CE/bin ]; then
    rm -rf $CE/bin
  fi

  if [ -d $CE/lib ]; then
    rm -rf $CE/lib
  fi
fi

if [ ! -z "$VCPKG_REMOVE" ]; then
  if [ -d $CE/node_modules ]; then
    echo Removing vcpkg-ce package
    rm -rf $CE/node_modules
  fi

  if [ -d $CE/bin ]; then
    rm -rf $CE/bin
  fi

  if [ -d $CE/lib ]; then
    rm -rf $CE/lib
  fi

  if [ -f $VCPKG_ROOT/ce.ps1 ]; then
    rm -f $VCPKG_ROOT/ce.ps1
  fi

  if [ -f $VCPKG_ROOT/ce ]; then
    rm -f $VCPKG_ROOT/ce
  fi

  if [ -f $VCPKG_ROOT/NOTICE.txt ]; then
    rm -f $VCPKG_ROOT/NOTICE.txt
  fi

  if [ -f $VCPKG_ROOT/LICENSE.txt ]; then
    rm -f $VCPKG_ROOT/LICENSE.txt
  fi

  # cleanup environment.
  . <(set | grep -i ^VCPKG | sed -e 's/[=| |\W].*//;s/^/unset /')

  # remove functions (zsh)
  which functions  > /dev/null 2>&1  && . <(functions | grep -i ^vcpkg | sed -e 's/[=| |\W].*//;s/^/unset -f /')
  return
fi

VCPKG_cleanup() {
  # clear things that we're not going to need for the long term
  unset VCPKG_NODE_LATEST
  unset VCPKG_NODE_REMOTE
  unset VCPKG_PWD
  unset VCPKG_NPM
  unset VCPKG_NESTED
  unset VCPKG_OS
  unset VCPKG_ARCH
  unset VCPKG_IS_THIS_BSD
  unset VCPKG_DEBUG
  unset -f VCPKG_bootstrap_node > /dev/null 2>&1
  unset -f VCPKG_bootstrap_ce > /dev/null 2>&1
  unset VCPKG_REMOVE
  unset VCPKG_RESET
  unset VCPKG_START_TIME
  unset VCPKG_ARGS
  if [ -f "${Z_VCPKG_POSTSCRIPT}" ]; then
    command rm "${Z_VCPKG_POSTSCRIPT}"
  fi
	unset Z_VCPKG_POSTSCRIPT
}
VCPKG_verify_node() {
  # $1 should be the folder to check
  local NODE_EXE="node"
  if [ "${VCPKG_OS}" = "win" ]; then
    NODE_EXE="node.exe"
  fi
  
  local N=$(which $1/$NODE_EXE)
  
    if [ ! -z "$N" ]; then
      if [ -f $N ]; then
        if [ $($N -e "[major, minor, patch ] = process.versions.node.split('.'); console.log( !!(major>16 || major == 16 & minor >= 12) )") = "true" ]; then
          VCPKG_NODE=$N
          VCPKG_NPM=$(which $1/npm)
          VCPKG_debug using node in $1
          return 0
        fi
      fi
    fi
    return 1;
}

VCPKG_find_node() {
  local NODES=$(find $1 | grep -i /bin/node)
  
  for each in $NODES; do 
    local d=$(dirname "$each")
    VCPKG_verify_node $d
    if [ $? -eq 0 ]; then
      return 0;
    fi
  done
  return 1;
}

VCPKG_bootstrap_node() {
  VCPKG_debug starting VCPKG_bootstrap_node

  # did we put one in downloads at some point?
  VCPKG_find_node $VCPKG_DOWNLOADS
  if [ $? -eq 0 ]; then
    return 0;
  fi

  # is there one on the path?
  VCPKG_find_node $(dirname $(which node))
  if [ $? -eq 0 ]; then
    return 0;
  fi

  local NODE_EXE="node"
  if [ "${VCPKG_OS}" = "win" ]; then
    NODE_EXE="node.exe"
  fi

  # we don't seem to have a suitable nodejs on the path
  # let's grab a well-known one, cache it and use it.

  local VCPKG_ARCHIVE_EXT=".tar.gz"
	local TAR_FLAGS="-zxvf"
	if [ "${VCPKG_OS}" = "win" ]; then
	  VCPKG_ARCHIVE_EXT=".zip"
  fi

  local NODE_FULLNAME="node-v${VCPKG_NODE_LATEST}-${VCPKG_OS}-${VCPKG_ARCH}"
  local NODE_URI="${VCPKG_NODE_REMOTE}v${VCPKG_NODE_LATEST}/${NODE_FULLNAME}${VCPKG_ARCHIVE_EXT}"
  local VCPKG_ARCHIVE="${VCPKG_DOWNLOADS}/${NODE_FULLNAME}${VCPKG_ARCHIVE_EXT}"

  if [ ! -d "${VCPKG_DOWNLOADS}" ]; then
    command mkdir -p "${VCPKG_DOWNLOADS}"
  fi

  echo "Downloading node from ${NODE_URI} to ${VCPKG_ARCHIVE}"
  if type noglob > /dev/null 2>&1; then
    noglob curl -L4 -# "${NODE_URI}" -o "${VCPKG_ARCHIVE}"
  else
    curl -L4 -# "${NODE_URI}" -o "${VCPKG_ARCHIVE}"
  fi

   if [ ! -f "${VCPKG_ARCHIVE}" ]; then
    echo "Failed to download node binary."
    return 1
  fi

  # UNPACK IT
  if [ "${VCPKG_OS}" = "aix" ]; then
    gunzip "${VCPKG_ARCHIVE}" | tar -xvC "${VCPKG_DOWNLOADS}" "${NODE_FULLNAME}/bin/${NODE_EXE}" >> $VCPKG_ROOT/log.txt 2>&1
  else
    tar $TAR_FLAGS "${VCPKG_ARCHIVE}" -C "${VCPKG_DOWNLOADS}" >> $VCPKG_ROOT/log.txt 2>&1
  fi
  
  # OK, we good?
  VCPKG_find_node $VCPKG_DOWNLOADS
  if [ $? -eq 0 ]; then
    return 0;
  fi

  if [ ! -f $VCPKG_NPM ]; then
    echo "ERROR! Unable to find/get npm"
    return 1;
  fi

  VCPKG_debug installed node in ce
  return 0
}

VCPKG_SCRIPT=${CE}/node_modules/.bin/ce
VCPKG_MAIN=${CE}/node_modules/vcpkg-ce

VCPKG_bootstrap_ce() {
  VCPKG_debug checking for installed ce $VCPKG_SCRIPT

  if [ -f $VCPKG_SCRIPT ]; then
    VCPKG_debug ce is installed.
    return 0
  fi

  # it's not there!
  # let's install it where we want it

  # ensure we have a node_modules here, so npm won't search for one up the tree.
  command mkdir -p $CE/node_modules

  echo Installing vcpkg-ce in $VCPKG_ROOT
  unset VCPKG_RESET

  cd $CE
  $VCPKG_NODE $VCPKG_NPM cache clean --force >> $VCPKG_ROOT/log.txt 2>&1
  local OLD_PATH=$PATH
  PATH=`dirname $VCPKG_NODE`:$PATH
  if [ ! -z "$USE_LOCAL_VCPKG_PKG" ]; then
    echo USING LOCAL CE PACKAGE $USE_LOCAL_VCPKG_PKG

    $VCPKG_NODE $VCPKG_NPM --force install --no-save --no-lockfile --scripts-prepend-node-path=true $USE_LOCAL_VCPKG_PKG  >> $VCPKG_ROOT/log.txt 2>&1
  else
    $VCPKG_NODE $VCPKG_NPM --force install --no-save --no-lockfile --scripts-prepend-node-path=true https://github.com/fearthecowboy/scratch/raw/main/vcpkg-ce.tgz  >> $VCPKG_ROOT/log.txt 2>&1
  fi

  PATH=$OLD_PATH
# go back where we were
  cd $VCPKG_PWD

  cp $CE/node_modules/.bin/ce* $VCPKG_ROOT/

  # Copy the NOTICE and LICENSE files to $VCPKG_ROOT to improve discoverability.
  cp $CE/node_modules/vcpkg-ce/NOTICE.txt $VCPKG_ROOT/
  cp $CE/node_modules/vcpkg-ce/LICENSE.txt $VCPKG_ROOT/

  if [  ! -f $VCPKG_SCRIPT ]; then
    echo "ERROR! Unable to find/get ce script command $VCPKG_SCRIPT"
    return 1;
  fi

  VCPKG_debug ce is installed
  return 0;
}

# first, let's make sure we have a good copy of node
VCPKG_bootstrap_node

if [ $? -eq 1 ]; then
  VCPKG_debug failed to acquire node.js
  VCPKG_cleanup
  return 1;
fi

VCPKG_bootstrap_ce

# is ce installed?
if [ $? -eq 1 ]; then
  VCPKG_debug failed to bootstrap ce
  VCPKG_cleanup
  return 1;
fi

if [ -z $VCPKG_NESTED ]; then
  VCPKG_debug executing final script: $VCPKG_SCRIPT
  VCPKG_NESTED=TRUE
  . $VCPKG_SCRIPT $VCPKG_ARGS
  return # let the real script take over from here.
fi

# So, we're the real script then.
VCPKG_debug 'real ce adding function'

ce() {
  # set | grep -i ^VCPKG

  local cst=$VCPKG_START_TIME

  VCPKG_init "$@"

  if [ ! -z "$VCPKG_RESET" ]; then
    if [ -d $CE/node_modules ]; then
      echo Forcing reinstall of vcpkg-ce package
      rm -rf $CE/node_modules
    fi

    if [ -d $CE/bin ]; then
      rm -rf $CE/bin
    fi

    if [ -d $CE/lib ]; then
      rm -rf $CE/lib
    fi
    unset VCPKG_RESET

    if [ ! -z "$USE_LOCAL_VCPKG_SCRIPT" ]; then
      echo USING LOCAL CE SCRIPT $USE_LOCAL_VCPKG_SCRIPT
      . <(cat $USE_LOCAL_VCPKG_SCRIPT) "${VCPKG_ARGS[@]}"
    else
      . <(curl -L4 -# https://raw.githubusercontent.com/fearthecowboy/scratch/main/update-ce.sh) "${VCPKG_ARGS[@]}"
    fi

    return 0
  fi

  if [ ! -z "$VCPKG_REMOVE" ]; then
    if [ -d $CE/node_modules ]; then
      unset VCPKG_REMOVE
      echo Removing vcpkg-ce package
      rm -rf $CE/node_modules
    fi

    if [ -d $CE/bin ]; then
      rm -rf $CE/bin
    fi

    if [ -d $CE/lib ]; then
      rm -rf $CE/lib
    fi

    if [ -f $VCPKG_ROOT/ce.ps1 ]; then
      rm -f $VCPKG_ROOT/ce.ps1
    fi

    if [ -f $VCPKG_ROOT/ce ]; then
      rm -f $VCPKG_ROOT/ce
    fi

    if [ -f $VCPKG_ROOT/NOTICE.txt ]; then
      rm -f $VCPKG_ROOT/NOTICE.txt
    fi

    if [ -f $VCPKG_ROOT/LICENSE.txt ]; then
      rm -f $VCPKG_ROOT/LICENSE.txt
    fi

    # cleanup environment
    . <(set | grep -i ^VCPKG | sed -e 's/[=| |\W].*//;s/^/unset /')

    # remove functions (zsh)
    which functions  > /dev/null 2>&1  && . <(functions | grep -i ^vcpkg | sed -e 's/[=| |\W].*//;s/^/unset -f /')
    return 0
  fi

  if [ ! -f $VCPKG_NODE ]; then
    echo The installation of nodejs $VCPKG_NODE that ce is using is missing
    echo You may need to reacquire ce with '. <(curl https://raw.githubusercontent.com/fearthecowboy/scratch/main/update-ce.sh -L4)'
    echo or fix your nodejs installation.
  fi

  if [ ! -d $VCPKG_MAIN ]; then
    echo The installation of ce is corrupted. $VCPKG_MAIN
    echo You may need to reacquire ce with '. <(curl https://raw.githubusercontent.com/fearthecowboy/scratch/main/update-ce.sh -L4)'
  fi

  # set the response file
	# Generate 32 bits of randomness, to avoid clashing with concurrent executions.
	export Z_VCPKG_POSTSCRIPT="${VCPKG_ROOT}/VCPKG_tmp_$(dd if=/dev/urandom count=1 2> /dev/null | cksum | cut -f1 -d" ").sh"

  # call ce.js
  # it picks up the Z_VCPKG_POSTSCRIPT environment variable to know where to dump the postscript
  $VCPKG_NODE --harmony $VCPKG_MAIN ${VCPKG_ARGS[@]}

  VCPKG_debug called ce.js
  # modify the environment

  # Call the post-invocation script if it is present, then delete it.
	# This allows the invocation to potentially modify the caller's environment (e.g. PATH)
	if [ -f "${Z_VCPKG_POSTSCRIPT}" ]; then
		. "${Z_VCPKG_POSTSCRIPT}"
		command rm "${Z_VCPKG_POSTSCRIPT}"
		unset Z_VCPKG_POSTSCRIPT
	fi

  VCPKG_cleanup

  VCPKG_START_TIME=$cst
}

# did they dotsource and have args go ahead and run it then!
if [ -n "$VCPKG_ARGS" ]; then
  ce "${VCPKG_ARGS[@]}"
fi

VCPKG_cleanup
