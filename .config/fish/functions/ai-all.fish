function ai-all
    for f in ~/Descargas/*.AppImage
        if test -f "$f"
            echo "→ Procesando: $f"
            ~/bin/appimage-install.sh "$f"
        end
    end
end
