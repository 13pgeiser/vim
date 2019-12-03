#!/bin/bash
set -e

echo "**********************************************"
echo "OSTYPE:   $OSTYPE"
echo "HOSTTYPE: $HOSTTYPE"
echo "**********************************************"
echo

ORIGINAL_PATH="$PATH"

# fatal "<error message>"
# End of story...
function fatal
{
  echo "FAILED!!!"
  echo "$1"
  echo "**********************************************"
  exit 1
}

# Force an update of apt lists on Travis CI
if [ "$USER" == "travis" ]; then
  sudo apt-get update
fi

# install_packages "<package>" ["<package>" ...]
# Install Debian packages using sudo
function install_packages
{
  for package in "$1"; do
    if ! dpkg-query -f '${Status}' -s $package | grep 'install ok' 2>/dev/null 1>/dev/null; then
      echo "Installing $package"
      sudo apt-get -y install $package
    fi
  done
}

# variable=$(detect_tools_folder)
# set global variable $TOOLS_FOLDER
# with the path where all tools
# will be installed.
function detect_tools_folder
{
  if [ -d ../tools ]; then
    TOOLS_FOLDER=$(realpath ../tools)
  else
    TOOLS_FOLDER=$(realpath tools)
  fi
  mkdir -p "$TOOLS_FOLDER"
}

# download "<md5sum hash>" "<url>" ["<archive>"]
# Download url and verify downloaded file.
function download
{
  if [ -z $3 ]; then
    local archive="$(basename $2)"
  else
    local archive="$3"
  fi
  if [ ! -e $TOOLS_FOLDER/$archive ]; then
    echo "Downloading $archive"
    echo "$cmd"
    cmd="curl -kSL "$2" --progress-bar -o $TOOLS_FOLDER/${archive}.tmp"
    $cmd
    if [[ "`md5sum $TOOLS_FOLDER/${archive}.tmp | cut -d' ' -f1`" != "$1" ]]; then
      fatal "Invalid md5sum for $archive: `md5sum TOOLS_FOLDER/${archive}.tmp`"
    fi
    mv $TOOLS_FOLDER/${archive}.tmp $TOOLS_FOLDER/$archive
  fi
}

# download_unpack "<md5sum hash>" "<url>" ["<flags>", "archive", "folder"]
# flags: 'c' -> create_folder
# flags: 'p' -> add folder to PATH
# flags: 'd' -> echo destination folder
function download_unpack
{
  if [ -z $4 ]; then
    local archive="$(basename $2)"
  else
    local archive="$4"
  fi
  download "$1" "$2" "$archive"
  if [ -z $5 ]; then
    local folder="${archive%.*}"
  else
    local folder="$5"
  fi
  local extension="${archive##*.}"
  local base_name="${archive%.*}"
  local extension_bis="${base_name##*.}"
  if [ "$extension_bis" == "tar" ]; then
    local folder="${folder%.*}"
    local extension="$extension_bis.$extension"
  fi
  if [ -z "`echo $3 | grep c`" ]; then
    local dst_folder="$TOOLS_FOLDER"
  else
    local dst_folder="$TOOLS_FOLDER/$folder"
  fi
  echo "### $TOOLS_FOLDER/$folder/.$archive ###"
  if [ ! -e $TOOLS_FOLDER/$folder/.$archive ]; then
    echo "Unpacking $archive"
    case "$extension" in
      "zip")
        unzip -q "$TOOLS_FOLDER/$archive" -d "$dst_folder"
        ;;
      "7z"|"rar")
        install_7zip
        7z x -o"$dst_folder" "$TOOLS_FOLDER/$archive"
        ;;
      "tgz")
        mkdir -p $dst_folder
        tar -C "$dst_folder" -xzf "$TOOLS_FOLDER/$archive"
        ;;
      "tar.xz")
        mkdir -p $dst_folder
        tar -C "$dst_folder" -xJf "$TOOLS_FOLDER/$archive"
        ;;
      "tar.bz2")
        mkdir -p $dst_folder
        tar -C "$dst_folder" -xjf "$TOOLS_FOLDER/$archive"
        ;;
      *)
        fatal "Unsupported file extension: $extension"
        ;;
    esac
    echo "touch $TOOLS_FOLDER/$folder/.$archive"
    touch "$TOOLS_FOLDER/$folder/.$archive"
  fi
  if [ ! -z "`echo $3 | grep p`" ]; then
    PATH="$PATH:$dst_folder"
  fi
  result="$TOOLS_FOLDER/$folder"
}

# install_7zip
# On windows, download first 7za, then 7zip
# On debian, install p7zip-full
function install_7zip
{
  case "$OSTYPE" in
    msys)
      download_unpack 2fac454a90ae96021f4ffc607d4c00f8 https://www.7-zip.org/a/7za920.zip cp
      local url="https://www.7-zip.org/a/7z1902-x64.exe" c
      local archive="$(basename $url)"
      local folder="${archive%.*}"
      download 6fe79bec6bf751293a1271bd739c8eb0 $url
      if [ ! -d "$TOOLS_FOLDER/$folder" ]; then
        7za x -o$TOOLS_FOLDER/$folder $TOOLS_FOLDER/$archive
      fi
      PATH="$PATH:$TOOLS_FOLDER/$folder"
      ;;
    linux*)
      install_packages p7zip-full
      ;;
    *)
      fatal "Unsupported OS: $OSTYPE"
      ;;
  esac
}

# install_innounp
# On windows, install innounp.exe
# Not implemented in linux
function install_innounp
{
  case "$OSTYPE" in
    msys)
      download_unpack 81e68ff6f7c21b0cacd506569b363c2a https://netix.dl.sourceforge.net/project/innounp/innounp/innounp%200.49/innounp049.rar cp
      ;;
    *)
      fatal "Unimplemented (innounp)"
      ;;
  esac
}

# install_qp_qm
# Download full bundle of QPC / QM
function install_qp_qm
{
  case "$OSTYPE" in
    msys)
      install_innounp
      local url="https://github.com/QuantumLeaps/qp-bundle/releases/download/v6.6.0/qp-windows_6.6.0.exe"
      local url="https://gitlab.com/pgeiser/qp_bundle/raw/master/qp-windows_6.6.0.exe"
      local archive="$(basename $url)"
      local folder="${archive%.*}"
      download 85acfe6a1412a5256001d9d97e16f17d $url
      if [ ! -d "$TOOLS_FOLDER/$folder" ]; then
        innounp -q -x -d"$TOOLS_FOLDER/$folder" "$TOOLS_FOLDER/$archive"
        for file in `ls "$TOOLS_FOLDER/$folder/{app}"`
        do
          mv "$TOOLS_FOLDER/$folder/{app}/$file" "$TOOLS_FOLDER/$folder"
        done
        rm -rf "$TOOLS_FOLDER/$folder/{app}/"
      fi
      QPC_BUNDLE="$TOOLS_FOLDER/$folder"
      ;;
    linux*)
      download_unpack 04874ed79f6cce43354771ba6090c728 https://github.com/QuantumLeaps/qp-bundle/releases/download/v6.6.0/qp-linux_6.6.0.zip c
      QPC_BUNDLE="$result/qp"
      chmod +x $QPC_BUNDLE/qm/bin/qm
      ;;
    *)
      fatal "Unsupported OS: $OSTYPE"
      ;;
  esac
}

# install_ninja
function install_ninja
{
  case "$OSTYPE" in
    msys)
      download_unpack 14764496d99bb5ea99e761dab9a38bc4 https://github.com/ninja-build/ninja/releases/download/v1.9.0/ninja-win.zip cp
      ;;
    linux*)
      install_packages ninja
      ;;
    *)
      fatal "Unsupported OS: $OSTYPE"
      ;;
  esac
}

# install_buildessentials
function install_buildessentials
{
  case "$OSTYPE" in
    msys)
      download_unpack 55c00ca779471df6faf1c9320e49b5a9 http://downloads.sourceforge.net/project/mingw-w64/Toolchains%20targetting%20Win64/Personal%20Builds/mingw-builds/8.1.0/threads-posix/seh/x86_64-8.1.0-release-posix-seh-rt_v6-rev0.7z c
      PATH="$PATH:$result/mingw64/bin"
      download_unpack a5abcf7d9cac9d3680b819613819f3c6 http://repo.msys2.org/msys/x86_64/make-4.2.1-1-x86_64.pkg.tar.xz cp
      MAKE_PATH="$result/usr/bin"
      PATH="$PATH:$MAKE_PATH"
      ;;
    linux*)
      install_packages build-essential
      ;;
    *)
      fatal "Unsupported OS: $OSTYPE"
      ;;
  esac

}

# Install gcc for arm
function install_gcc_for_arm
{
  case "$OSTYPE" in
    msys)
      download_unpack 82525522fefbde0b7811263ee8172b10 https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/RC2.1/gcc-arm-none-eabi-9-2019-q4-major-win32.zip.bz2 c gcc-arm-none-eabi-9-2019-q4-major-win32.zip
      PATH="$PATH:$result//bin"
      ;;
    linux*)
      download_unpack fe0029de4f4ec43cf7008944e34ff8cc https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/RC2.1/gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2 c
      PATH="$PATH:$result/gcc-arm-none-eabi-9-2019-q4-major/bin"
      ;;
    *)
      fatal "Unsupported OS: $OSTYPE"
      ;;
  esac
  cat <<EOF >arm-none-eabi.cmake
# Automatically created by the configure script
# DO NOT EDIT MANUALLY!
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)
set(CMAKE_C_COMPILER arm-none-eabi-gcc)
set(CMAKE_CXX_COMPILER arm-none-eabi-g++)
set(CMAKE_ASM_COMPILER arm-none-eabi-gcc)
set(CMAKE_OBJCOPY arm-none-eabi-objcopy)
set(CMAKE_OBJDUMP arm-none-eabi-objdump)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
EOF
}

# install_cmake
function install_cmake
{
  case "$OSTYPE" in
    msys)
      install_ninja
      download_unpack f97acefa282588f05c6528d6db37c570 https://github.com/Kitware/CMake/releases/download/v3.15.5/cmake-3.15.5-win64-x64.zip
      PATH="$PATH:$result/bin"
      ;;
    linux*)
      install_packages cmake
      ;;
    *)
      fatal "Unsupported OS: $OSTYPE"
      ;;
  esac
}

function install_subversion
{
  case "$OSTYPE" in
    msys)
      download_unpack 757a8abc7bcf363f57c7aea34bcd3a36 https://www.visualsvn.com/files/Apache-Subversion-1.13.0.zip c
      PATH="$PATH:$result/bin"
      ;;
    linux*)
      install_packages subversion
      ;;
    *)
      fatal "Unsupported OS: $OSTYPE"
      ;;
  esac
}

# call_cmake
# Use ninja on windows, make on linux.
function call_cmake
{
  install_cmake
  case "$OSTYPE" in
    msys)
      cmake -G "MSYS Makefiles" . $@
      ;;
    linux*)
      cmake . $@
      ;;
    *)
      fatal "Unsupported OS: $OSTYPE"
      ;;
  esac
}

function write_sourceme
{
  cat <<EOF >sourceme
#!/bin/bash
export LANG=C
alias tags="ctags -R --c++-kinds=+p --fields=+iaS --extra=+q ."
alias ls='ls -F --color --show-control-chars'
export LC_MESSAGES=C
function g() {
  gitk --all &
}

gg() {
  gitk --all &
    git gui &
  }
EOF
echo "PATH=\"$PATH\"" >>sourceme
}
