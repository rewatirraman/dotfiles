# bash_env
Customised .vimrc, .bashrc, and .vim (with some useful plugins......) 

# 
```
rm -rf ~/.bashrc ~/.vimrc ~/.vim

cp -R .bashrc .vimrc .vim ~/
```
#
Post installation of .vim directory, you might observe error as below while opening any file using `vi` editor
this probably because of missing package vim-gui-common.

```
  E319: Sorry, the command is not available in this version: try
```

Please install below packages to fix the above error:

```
sudo apt-get install vim-gui-common

sudo apt-get install vim-runtime
```
  
 
