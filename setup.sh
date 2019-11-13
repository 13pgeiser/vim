#!/bin/bash
set -e

# Folder where this script lives in.
SCRIPT_FOLDER=`dirname "$(readlink -f "$0")"`

# End of story....
function fatal
{
    echo "FAILED!!!"
    echo $1
    echo "**********************************************"
    exit 1
}

# VIM_FOLDER
case "$OSTYPE" in
    msys)
        VIM_FOLDER="$SCRIPT_FOLDER/vim81"
        ;;
    linux*)
        VIM_FOLDER="$SCRIPT_FOLDER"
        ;;
    *)
        fatal "Unsupported OS: $OSTYPE"
        ;;
esac

CURL="curl -kSL"
if [[ -v HTTP_PROXY ]]; then
    CURL="$CURL --proxy $HTTP_PROXY"
fi

# Download file and check md5 sum
function download
{
    ARCHIVE=`basename $1`
    if [[ ! -e $ARCHIVE ]]; then
        echo "Downloading $ARCHIVE"
        cmd="$CURL $1 --progress-bar -o $ARCHIVE"
        echo $cmd
        $cmd
    fi
    if [[ "`md5sum $ARCHIVE | cut -d' ' -f1`" != "$2" ]]; then
        fatal "Invalid MD5 for $ARCHIVE: `md5sum $ARCHIVE`"
    fi
}

function download_unpack
{
    download "$1" "$2"
    ARCHIVE=`basename $1`
    FOLDER=${ARCHIVE%.*}
    EXTENSION=${ARCHIVE##*.}
    if [ ! -e $FOLDER ]; then
        echo "Unpacking $ARCHIVE"
        if [ "$EXTENSION" == "zip" ]; then
            if [ "$3" == "nofolder" ]; then
                unzip -q $ARCHIVE
            else
                unzip -q $ARCHIVE -d $FOLDER
            fi
        elif [ "$EXTENSION" == "7z" ]; then
            if [ "$3" == "nofolder" ]; then
                7za x $ARCHIVE
            else
                7za x -o$FOLDER $ARCHIVE
            fi
        else
            echo "Unsupported $EXTENSION"
        fi
    fi
}

# Download and unpack Vim
case "$OSTYPE" in
    "msys")
        if [ ! -d "$VIM_FOLDER" ]; then
            VERSION=8.1.2291
            download_unpack https://github.com/vim/vim-win32-installer/releases/download/v${VERSION}/gvim_${VERSION}_x64_signed.zip 063a6099f7900b166899c645097e6da2
            mv $FOLDER/vim/vim81 $VIM_FOLDER
            rm -rf $FOLDER
            rm -f $ARCHIVE
        fi
        ;;
    linux*)
        if [ -v DISPLAY ]; then
            if ! dpkg-query -l vim-gtk3 2>/dev/null 1>/dev/null; then
                echo "Installing vim-gtk3"
                sudo apt-get update && sudo apt-get -y install vim-gtk3
            fi
        else
            if ! dpkg-query -l vim-nox 2>/dev/null 1>/dev/null; then
                echo "Installing vim-nox"
                sudo apt-get update && sudo apt-get -y install vim-nox
            fi
        fi
        ;;
    *)
        fatal "Unsupported OS: $OSTYPE"
        ;;
esac

if [ ! -e $VIM_FOLDER/autoload/pathogen.vim ]; then
    mkdir -p $VIM_FOLDER/autoload
    $CURL -o $VIM_FOLDER/autoload/pathogen.vim https://tpo.pe/pathogen.vim
fi

function install_plugin
{
    if [[ "$2" != "" ]]; then
        directory="$2"
    else
        directory=`basename $1`
        directory="${directory%.*}"
    fi
    mkdir -p $VIM_FOLDER/bundle
    PLUGIN=$VIM_FOLDER/bundle/$directory
    if [[ ! -e $PLUGIN ]]; then
        git clone $1 $PLUGIN --depth 1 --recurse-submodules
        rm -rf $PLUGIN/.git
    fi
}

install_plugin https://github.com/joshdick/onedark.vim.git
install_plugin https://github.com/scrooloose/nerdtree.git
install_plugin https://github.com/Xuyuanp/nerdtree-git-plugin.git
install_plugin https://github.com/vim-airline/vim-airline.git
install_plugin https://github.com/vim-airline/vim-airline-themes.git
install_plugin https://github.com/airblade/vim-gitgutter.git
install_plugin https://github.com/tpope/vim-fugitive.git
install_plugin https://github.com/tpope/vim-sensible.git
install_plugin https://github.com/tpope/vim-surround.git

install_plugin https://github.com/Valloric/YouCompleteMe.git
if [[ ! -e $PLUGIN/.installed ]]; then
    case "$OSTYPE" in
        "msys")
            PYTHON=/c/Python37
            cd $PLUGIN
            sed -i 's/cmake_args.extend( \[/#cmake_args.extend( \[/' third_party/ycmd/build.py
            egrep HAVE_SNPRINTF third_party/ycmd/cpp/ycm/ClangCompleter/ClangHelpers.cpp ||sed -i 's/#include "ClangHelpers.h"/#define HAVE_SNPRINTF\n#include "ClangHelpers.h"/' third_party/ycmd/cpp/ycm/ClangCompleter/ClangHelpers.cpp
            download_unpack https://www.7-zip.org/a/7za920.zip 2fac454a90ae96021f4ffc607d4c00f8
            PATH=`pwd`/$FOLDER:$PATH
            download_unpack https://netix.dl.sourceforge.net/project/mingw-w64/Toolchains%20targetting%20Win64/Personal%20Builds/mingw-builds/8.1.0/threads-posix/seh/x86_64-8.1.0-release-posix-seh-rt_v6-rev0.7z 55c00ca779471df6faf1c9320e49b5a9
            PATH=`pwd`/$FOLDER/mingw64/bin:$PATH
            download_unpack https://github.com/Kitware/CMake/releases/download/v3.15.5/cmake-3.15.5-win64-x64.zip f97acefa282588f05c6528d6db37c570 "nofolder"
            PATH=`pwd`/$FOLDER/bin:$PATH
            download_unpack https://github.com/ninja-build/ninja/releases/download/v1.9.0/ninja-win.zip 14764496d99bb5ea99e761dab9a38bc4
            PATH=`pwd`/$FOLDER:$PATH
            $PYTHON/python.exe install.py --ninja --clang-completer
            cp $PYTHON/python37.dll $VIM_FOLDER
            touch $PLUGIN/.installed
            ;;
        linux-*)
            sudo apt-get update
            sudo apt-get install -y build-essential python3-dev libclang-dev
            if hash cmake 2>/dev/null; then
                echo "cmake already installed"
            else
                sudo apt-get install -y cmake
            fi
            cd $VIM_FOLDER/bundle/YouCompleteMe/
            python3 ./install.py --system-libclang --clang-completer
            touch $PLUGIN/.installed
            ;;
        *)
            fatal "YouCompleteMe: Unsupported OS: $OSTYPE"
            ;;
    esac
    cd $VIM_FOLDER
fi

install_plugin https://github.com/junegunn/fzf.git
install_plugin https://github.com/junegunn/fzf.vim.git
if [[ ! -e $VIM_FOLDER/bundle/fzf/bin/fzf ]]; then
    VERSION=0.18.0
    case "$OSTYPE" in
        "msys")
            ARCHIVE=fzf-${VERSION}-windows_amd64.zip
            MD5=0fe7965138541c0b0ee49f9d11bba9cf
            ;;
        "linux-gnu")
            ARCHIVE=fzf-${VERSION}-linux_amd64.tgz
            MD5=7a1b249b4004e70121370abb8fe3ecc4
            ;;
        "linux-gnueabihf")
            ARCHIVE=fzf-${VERSION}-linux_arm7.tgz
            MD5=8e38e5487063622110146245b7f5dcbc
            ;;
        *)
            fatal "FZF: Unsupported OS: $OSTYPE"
            ;;
    esac
    download https://github.com/junegunn/fzf-bin/releases/download/${VERSION}/$ARCHIVE $MD5
    echo "${ARCHIVE##*.}"
    if [ "${ARCHIVE##*.}" == "zip" ]; then
        unzip  $ARCHIVE
    else
        tar xzf $ARCHIVE
    fi
    mv fzf $VIM_FOLDER/bundle/fzf/bin/
    rm -f $ARCHIVE
fi

install_plugin https://github.com/mileszs/ack.vim.git
if [[ ! -e $VIM_FOLDER/ag ]]; then
    case "$OSTYPE" in
        "msys")
            ARCHIVE=ag-2018-08-08_2.2.0-2-gbd82cd3-x64.zip
            download https://github.com/k-takata/the_silver_searcher-win32/releases/download/2018-08-08%2F2.2.0-2-gbd82cd3//$ARCHIVE 0d76cae5d89dd5e6a42603505f155bc3
            unzip  $ARCHIVE -d ag
            mv ag/ag $VIM_FOLDER
            rm -rf ag
            rm -f $ARCHIVE
            ;;
        linux-*)
            echo "Check for AG"
            if ! dpkg-query -l silversearcher-ag 2>/dev/null 1>/dev/null; then
                echo "Installing silversearcher-ag"
                sudo apt-get update && sudo apt-get install -y silversearcher-ag
            fi
            ;;
        *)
            fatal "Ag: Unsupported OS: $OSTYPE"
            ;;
    esac
fi
