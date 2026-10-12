function cshell
    qs kill -p /home/kei/.config/quickshell/caelestia
    sleep 1
    env QS_ICON_THEME=Papirus-Dark qs -n -p /home/kei/.config/quickshell/caelestia -d
end
