#!/bin/bash
set -e

echo ""
echo "                      .,"
echo "    .,ggggggggggggggg,t 7,  ,ygggggggggggggg,"
echo "    m                m    7Jb               Jr"
echo "    m               .m     .p               Jr"
echo "     TMr          .PR       .PR           .M<"
echo "      Jr          .p      .,R           .2<"
echo "      Jr          _p    _,R           _Jt"
echo "      Jr          .p  .,F           .J5"
echo "      Jr          _p_,F           .,R Ju"
echo "     ,Gr          _mF            ,F     Ju"
echo "   _f Jr          _            ,F         J&"
echo " _f   Jr                     ,F             Jp"
echo "  %;. Jr                 J*^7P            .y="
echo "    %;4r                ,p__J           .g="
echo "      Gr               gMegg.gggg,_,ggggmggg,"
echo "      Jr             _M;  _PJp    ^    /    Jr"
echo "      Jr           _M<,t  J ,<  Jem   ;Hm  _P"
echo "      Jr         _2< _P  ,t_P  ,bqb  J~_b  J"
echo "      Jr       _g<   J  _m_g  _mPy  _m_p  _m"
echo "      Jr     .J*%;. ,m,,,a,m,,,m,m,,,pJg,,,p"
echo "      .%Qggggt    %;.     .gF"
echo "                   .%;. .gF"
echo "                     .%yF"
echo ""
echo "**********************************************"
echo "*        Welcome to Vim installer            *"
echo "**********************************************"
echo ""

source _bash_helpers.sh

# Folder where this script lives in.
TOOLS_FOLDER=$(dirname "$(readlink -f "$0")")

# VIM_FOLDER
case "$OSTYPE" in
  msys)
    VIM_FOLDER="$TOOLS_FOLDER/vim81"
    ;;
  linux*)
    VIM_FOLDER="$TOOLS_FOLDER"
    ;;
  *)
    fatal "Unsupported OS: $OSTYPE"
    ;;
esac

# Download and unpack Vim
echo "Installing VIM..."
case "$OSTYPE" in
  "msys")
    if [ ! -d "$VIM_FOLDER" ]; then
      VERSION=8.1.2291
      download_unpack 063a6099f7900b166899c645097e6da2 https://github.com/vim/vim-win32-installer/releases/download/v${VERSION}/gvim_${VERSION}_x64_signed.zip
      mv vim/vim81 "$VIM_FOLDER"
      rm -rf vim
    fi
    ;;
  linux*)
    if [ -v DISPLAY ]; then
      install_packages vim-gtk3
    else
      install_packages vim-nox
    fi
    install_packages fonts-powerline
    ;;
  *)
    fatal "Unsupported OS: $OSTYPE"
    ;;
esac

if [ ! -e "$VIM_FOLDER/autoload/pathogen.vim" ]; then
  download eb4e4f0c8ca51ae15263c9255dfd6094 https://tpo.pe/pathogen.vim
  mkdir -p "$VIM_FOLDER/autoload"
  mv pathogen.vim "$VIM_FOLDER/autoload"
fi

function install_plugin
{
  if [[ "$2" != "" ]]; then
    directory="$2"
  else
    directory=$(basename "$1")
    directory="${directory%.*}"
  fi
  mkdir -p "$VIM_FOLDER/bundle"
  PLUGIN=$VIM_FOLDER/bundle/$directory
  echo "Installing $(basename "$1")"
  if [[ ! -e $PLUGIN ]]; then
    git clone "$1" "$PLUGIN" --depth 1 --recurse-submodules
    rm -rf "$PLUGIN/.git"
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

TOOLS_FOLDER="$VIM_FOLDER"
install_plugin https://github.com/Valloric/YouCompleteMe.git
if [[ ! -e "$PLUGIN/.installed" ]]; then
  cd "$PLUGIN"
  case "$OSTYPE" in
    "msys")
      PYTHON=/c/Python37
      sed -i 's/cmake_args.extend( \[/#cmake_args.extend( \[/' third_party/ycmd/build.py
      grep -e HAVE_SNPRINTF third_party/ycmd/cpp/ycm/ClangCompleter/ClangHelpers.cpp ||sed -i 's/#include "ClangHelpers.h"/#define HAVE_SNPRINTF\n#include "ClangHelpers.h"/' third_party/ycmd/cpp/ycm/ClangCompleter/ClangHelpers.cpp
      install_buildessentials
      install_cmake
      "$PYTHON/python.exe" install.py --ninja --clang-completer
      cp "$PYTHON/*.dll" "$VIM_FOLDER"
      cp "$(dirname "$(command -v gcc)")/*.dll" "$VIM_FOLDER"
      cp ./third_party/ycmd/third_party/clang/lib/libclang.dll ./third_party/ycmd/
      touch "$PLUGIN/.installed"
      ;;
    linux-*)
      install_packages build-essential python3-dev libclang-dev cmake golang rustc cargo
      install_cmake
      case "$OSTYPE" in
        "msys")
          python3 ./install.py --clang-completer --rust-completer --java-completer
          ;;
        "linux-gnu")
          python3 ./install.py --clang-completer --rust-completer --java-completer
          ;;
        "linux-gnueabihf")
          python3 ./install.py --clang-completer --java-completer
          ;;
        *)
          fatal "Unsupported OS: $OSTYPE"
          ;;
      esac
      touch "$PLUGIN/.installed"
      ;;
    *)
      fatal "YouCompleteMe: Unsupported OS: $OSTYPE"
      ;;
  esac
  cd "$VIM_FOLDER"
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
  download_unpack "$MD5" "https://github.com/junegunn/fzf-bin/releases/download/${VERSION}/$ARCHIVE"
  mv "$TOOLS_FOLDER/fzf" "$VIM_FOLDER/bundle/fzf/bin/"
fi

install_plugin https://github.com/mileszs/ack.vim.git
if [[ ! -e $VIM_FOLDER/ag ]]; then
  case "$OSTYPE" in
    "msys")
      ARCHIVE=ag-2018-08-08_2.2.0-2-gbd82cd3-x64.zip
      download_unpack 0d76cae5d89dd5e6a42603505f155bc3 https://github.com/k-takata/the_silver_searcher-win32/releases/download/2018-08-08%2F2.2.0-2-gbd82cd3//$ARCHIVE c
      mv "$result/ag" "$VIM_FOLDER"
      ;;
    linux-*)
      echo "Check for AG"
      install_packages silversearcher-ag
      ;;
    *)
      fatal "Ag: Unsupported OS: $OSTYPE"
      ;;
  esac
fi

echo "Done!"

