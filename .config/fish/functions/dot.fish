function dot --wraps='git --git-dir=$HOME/.dotfiles.git --work-tree=$HOME' --description 'alias dot git --git-dir=$HOME/.dotfiles.git --work-tree=$HOME'
    git --git-dir=$HOME/.dotfiles.git --work-tree=$HOME $argv
end
