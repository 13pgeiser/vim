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
if [[ -v http_proxy ]]; then
	CURL="$CURL --proxy $http_proxy"
fi

# Download file and check md5 sum
function download
{
    ARCHIVE=`basename $1`
    if [[ ! -e $ARCHIVE ]]; then
        echo "Downloading $ARCHIVE"
        $CURL $1 --progress-bar -o $ARCHIVE
    fi
    if [[ "`md5sum $ARCHIVE | cut -d' ' -f1`" != "$2" ]]; then
        fatal "Invalid MD5 for $ARCHIVE"
    fi
}

# Download and unpack Vim
case "$OSTYPE" in
    "msys")
        if [ ! -d "$VIM_FOLDER" ]; then
            ARCHIVE=gvim_8.1.0536_x86.zip
            download https://github.com/vim/vim-win32-installer/releases/download/v8.1.0536/$ARCHIVE 1a0b486a0a2a6912698b0ef903db1180
            echo "Unpacking $ARCHIVE"
            unzip -q $ARCHIVE
            rm -f $ARCHIVE
            mv vim/vim81 $VIM_FOLDER
            rm -rf vim
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
    if [[ ! -e $VIM_FOLDER/bundle/$directory ]]; then
        git clone $1 $VIM_FOLDER/bundle/$directory --depth 1
        rm -rf $VIM_FOLDER/bundle/$directory/.git
    fi
}

install_plugin https://github.com/mileszs/ack.vim.git
install_plugin https://github.com/joshdick/onedark.vim.git
install_plugin https://github.com/junegunn/fzf.git
install_plugin https://github.com/junegunn/fzf.vim.git
install_plugin https://github.com/scrooloose/nerdtree.git
install_plugin https://github.com/Xuyuanp/nerdtree-git-plugin.git
install_plugin https://github.com/vim-airline/vim-airline.git
install_plugin https://github.com/vim-airline/vim-airline-themes.git
install_plugin https://github.com/tpope/vim-fugitive.git
install_plugin https://github.com/airblade/vim-gitgutter.git
install_plugin https://github.com/tpope/vim-sensible.git
install_plugin https://github.com/tpope/vim-surround.git

if [[ ! -e $VIM_FOLDER/bundle/fzf/bin/fzf ]]; then
    case "$OSTYPE" in
        "msys")
            ARCHIVE=fzf-0.17.5-windows_amd64.zip
            download https://github.com/junegunn/fzf-bin/releases/download/0.17.5/$ARCHIVE a5f20ae3e8604ed8c1ed216bf0ead83a
            unzip  $ARCHIVE
            mv fzf $VIM_FOLDER/bundle/fzf/bin/
            rm -f $ARCHIVE
        ;;
        "linux-gnu")
            ARCHIVE=fzf-0.17.5-linux_amd64.tgz
            download https://github.com/junegunn/fzf-bin/releases/download/0.17.5/$ARCHIVE b5efb3d1655193d842b683f693c73d09
            tar xvzf $ARCHIVE
            mv fzf $VIM_FOLDER/bundle/fzf/bin/
            rm -f $ARCHIVE
        ;;
        *)
            fatal "FZF: Unsupported OS: $OSTYPE"
        ;;
    esac
fi

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
        "linux-gnu")
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
