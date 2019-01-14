#!/bin/sh
if [ ! -e autoload ]; then
	mkdir -p autoload
	curl -LSso autoload/pathogen.vim https://tpo.pe/pathogen.vim
fi
if [ ! -e bundle/fzf/bin/fzf ]; then
  curl -fsSL https://github.com/junegunn/fzf-bin/releases/download/0.17.5/fzf-0.17.5-linux_amd64.tgz -o bundle/fzf/fzf.tgz
  tar -C bundle/fzf/bin/ -xzf bundle/fzf/fzf.tgz
  rm -f bundle/fzf/fzf.tgz
fi

