#!/bin/bash
set -e

echo "**********************************************"
echo "OSTYPE:   $OSTYPE"
echo "HOSTTYPE: $HOSTTYPE"
echo "**********************************************"
echo

# fatal "<error message>"
# End of story...
function fatal
{
    echo "FAILED!!!"
    echo "$1"
    echo "**********************************************"
    exit 1
}

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

# download "<md5sum hash>" "<url>"
# Download url and verify downloaded file.
function download
{
  local archive=$(basename $2)
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

# download_unpack "<md5sum hash>" "<url>" ["<flags>", "extension"]
# flags: 'c' -> create_folder
# flags: 'p' -> add folder to PATH
# flags: 'd' -> echo destination folder
function download_unpack
{
  download "$1" "$2"
  local archive="$(basename $2)"
  local folder="${archive%.*}"
  local extension="${archive##*.}"
  if [ -z "`echo $3 | grep c`" ]; then
    local dst_folder="$TOOLS_FOLDER"
  else
    local dst_folder="$TOOLS_FOLDER/$folder"
  fi
  if [ ! -z "$4" ]; then
    local extension="$4"
  fi
  if [ ! -d $TOOLS_FOLDER/$folder ]; then
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
        tar -C "$dst_folder" -xzf "$TOOLS_FOLDER/$archive"
        ;;
      *)
        fatal "Unsupported file extension: $extension"
        ;;
    esac
  fi
  if [ ! -z "`echo $3 | grep p`" ]; then
    echo "Updating path with $dst_folder"
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
      download_unpack 55c00ca779471df6faf1c9320e49b5a9 https://netix.dl.sourceforge.net/project/mingw-w64/Toolchains%20targetting%20Win64/Personal%20Builds/mingw-builds/8.1.0/threads-posix/seh/x86_64-8.1.0-release-posix-seh-rt_v6-rev0.7z c
      PATH="$PATH:$result/mingw64/bin"
      ;;
    linux*)
      install_packages build-essential
      ;;
    *)
      fatal "Unsupported OS: $OSTYPE"
      ;;
  esac

}

# install_cmake
function install_cmake
{
  install_buildessentials
  case "$OSTYPE" in
    msys)
      install_ninja
      download_unpack f97acefa282588f05c6528d6db37c570 https://github.com/Kitware/CMake/releases/download/v3.15.5/cmake-3.15.5-win64-x64.zip
      echo PATH="$PATH:$result/bin"
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

# call_cmake
# Use ninja on windows, make on linux.
function call_cmake
{
  install_cmake
  case "$OSTYPE" in
    msys)
      cmake -G Ninja .
      ;;
    linux*)
      cmake .
      ;;
    *)
      fatal "Unsupported OS: $OSTYPE"
      ;;
  esac
}

