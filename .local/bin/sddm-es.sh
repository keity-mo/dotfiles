#!/usr/bin/env bash
t=/usr/share/sddm/themes/caelestia
sed -i 's|Loading\.\.\.|Cargando...|; s|Enter your password|Ingresa tu contraseña|' "$t/components/PasswordInput.qml"
sed -i 's|Caps Lock is activated!|¡Bloq Mayús está activado!|; s|Unlock for notifications|Desbloquea para ver las notificaciones|' "$t/Main.qml"
sed -i 's|"Good night"|"Buenas noches"|; s|"Good morning"|"Buenos días"|; s|"Good afternoon"|"Buenas tardes"|' "$t/widgets/WelcomeText.qml"
