#fedora fix 
#the file must be saved in cat /etc/profile.d/display.sh
#built with gemini::prompt: i need to fix anoying wayland issue with authorization. for example sudo gparted it give me cills and i don`t want to use disk management tool
#
export QT_X11_NO_MITSHM=1
[[ -z $DISPLAY && $XDG_SESSION_TYPE = "x11" ]] || xhost +si:localuser:root
