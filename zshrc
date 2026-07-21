# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Fix the Java Problem
export _JAVA_AWT_WM_NONREPARENTING=1

# Created by newuser for 5.9
source $HOME/powerlevel10k/powerlevel10k.zsh-theme

#ZSH AutoSuggestions Plugin

if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
	source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

#ZSH Syntax Highlighting

if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
	source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi	

#ZSH Sudo Plugin
if [ -f /usr/share/zsh-sudo/sudo.plugin.zsh ];then
	source /usr/share/zsh-sudo/sudo.plugin.zsh
fi

# Custom Aliases
# -----------------------------------------------
# bat
alias cat='bat'
alias catn='bat --style=plain'
alias catnp='bat --style=plain --paging=never'
 
# ls
alias ll='lsd -lh --group-dirs=first'
alias la='lsd -a --group-dirs=first'
alias l='lsd --group-dirs=first'
alias lla='lsd -lha --group-dirs=first'
alias ls='lsd --group-dirs=first'

#History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt histignorealldups sharehistory

# Use modern completion system
autoload -Uz compinit
compinit
 
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
 
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

export LS_COLORS="rs=0:di=34:ln=36:mh=00:pi=40;33:so=35:do=35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=00:tw=30;42:ow=34;42:st=37;44:ex=32:*.tar=31:*.tgz=31:*.arc=31:*.arj=31:*.taz=31:*.lha=31:*.lz4=31:*.lzh=31:*.lzma=31:*.tlz=31:*.txz=31:*.tzo=31:*.t7z=31:*.zip=31:*.z=31:*.dz=31:*.gz=31:*.lrz=31:*.lz=31:*.lzo=31:*.xz=31:*.zst=31:*.tzst=31:*.bz2=31:*.bz=31:*.tbz=31:*.tbz2=31:*.tz=31:*.deb=31:*.rpm=31:*.jar=31:*.war=31:*.ear=31:*.sar=31:*.rar=31:*.alz=31:*.ace=31:*.zoo=31:*.cpio=31:*.7z=31:*.rz=31:*.cab=31:*.wim=31:*.swm=31:*.dwm=31:*.esd=31:*.avif=35:*.jpg=35:*.jpeg=35:*.mjpg=35:*.mjpeg=35:*.gif=35:*.bmp=35:*.pbm=35:*.pgm=35:*.ppm=35:*.tga=35:*.xbm=35:*.xpm=35:*.tif=35:*.tiff=35:*.png=35:*.svg=35:*.svgz=35:*.mng=35:*.pcx=35:*.mov=35:*.mpg=35:*.mpeg=35:*.m2v=35:*.mkv=35:*.webm=35:*.webp=35:*.ogm=35:*.mp4=35:*.m4v=35:*.mp4v=35:*.vob=35:*.qt=35:*.nuv=35:*.wmv=35:*.asf=35:*.rm=35:*.rmvb=35:*.flc=35:*.avi=35:*.fli=35:*.flv=35:*.gl=35:*.dl=35:*.xcf=35:*.xwd=35:*.yuv=35:*.cgm=35:*.emf=35:*.ogv=35:*.ogx=35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:*~=00;90:*#=00;90:*.bak=00;90:*.old=00;90:*.orig=00;90:*.part=00;90:*.rej=00;90:*.swp=00;90:*.tmp=00;90:*.dpkg-dist=00;90:*.dpkg-old=00;90:*.ucf-dist=00;90:*.ucf-new=00;90:*.ucf-old=00;90:*.rpmnew=00;90:*.rpmorig=00;90:*.rpmsave=00;90:"

# PATH dinámico: agrega todos los bin/ dentro de /opt/ automáticamente
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/usr/sbin"
for dir in /opt/*/bin /opt/*/*/bin; do
    [[ -d "$dir" ]] && export PATH="$dir:$PATH"
done

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


#Custom funtions
#--------------------------------

#Refresh zshrc
function refresh(){
    source ~/.zshrc
}

#Set Target

function settarget(){
    ip_address=$1
    machine_name=$2
    echo "$ip_address $machine_name" > $HOME/.config/bin/target
}

#Set Clear Target

function cleartarget(){
    echo '' > $HOME/.config/bin/target
}


#Conect Wifi

function wificonect() {
    python3 $HOME/.config/bspwm/scripts/wifi_conect.py
}

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


#open scannig

wifiscan() {
    bash $HOME/.config/bspwm/scripts/tlwn722n-monitormode.sh "$@"
}



# Reset Services Network

resnet () {
    bash $HOME/.config/bspwm/scripts/restar_Ser.sh "$@"
}


# Mkdir

mkt () {
  mkdir {nmap,content,scripts,vpn}
}


#WhichSystem

function whichsystem() {
    python3 $HOME/.config/bspwm/scripts/WhichSystem.py "$@"
}

#Extract Ports

extractPorts () {
    ports="$(cat $1 | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"
    ip_address="$(cat $1 | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | sort -u | head -n 1)"

    echo -e "\n[*] Extracting information...\n" > extractPorts.tmp
    echo -e "\t[*] IP Address: $ip_address" >> extractPorts.tmp
    echo -e "\t[*] Open ports: $ports\n" >> extractPorts.tmp

    echo $ports | tr -d '\n' | xclip -sel clip
    echo -e "[*] Ports copied to clipboard\n" >> extractPorts.tmp

    bat extractPorts.tmp
    rm extractPorts.tmp
}

# RVM deshabilitado - no se usa (descomentar si se necesita)
# source /usr/local/rvm/scripts/rvm



#Ingresar directorio

alias cdm='cd $HOME/Desktop/Moskov/Ciberseguridad'

# Servicios de red (aplicativos interactivos)
alias startftp='bash /home/moskov/Desktop/Moskov/Ciberseguridad/1_Scripts/servicios/startftp.sh'
alias startssh='bash /home/moskov/Desktop/Moskov/Ciberseguridad/1_Scripts/servicios/startssh.sh'
alias startfire='bash /home/moskov/Desktop/Moskov/Ciberseguridad/1_Scripts/servicios/startfire.sh'
alias compartidos='bash /home/moskov/Desktop/Moskov/Ciberseguridad/1_Scripts/servicios/gestionar_compartidos.sh'

# Info Batería + Fecha/Hora (verde en terminal)

infbat() {
    BAT_PATH="/sys/class/power_supply/BAT0"
    if [ -f "$BAT_PATH/capacity" ]; then
        capacity=$(cat "$BAT_PATH/capacity")
        bat_status=$(cat "$BAT_PATH/status")
        if [ "$bat_status" = "Charging" ]; then
            icon=" Charging"
        elif [ "$bat_status" = "Full" ]; then
            icon=" Full"
        else
            icon=" Discharging"
        fi
        bat_info="$icon $capacity%%"
    else
        bat_info="No battery detected"
    fi
    datetime=$(date "+%A %d/%m/%Y  %H:%M:%S")
    echo -e "\033[0;32m  $datetime  |  $bat_info\033[0m"
}

# NetAudit - Herramienta de auditoría de red
# Modo interactivo (menú)
netaudit() {
    sudo /home/moskov/Desktop/Moskov/Ciberseguridad/01_Scripts/go/netaudit/netaudit "$@"
}

# NetAudit - Modo comando directo
netscan() {
    local cmd="$1"
    shift 2>/dev/null
    case "$cmd" in
        discover|scan|banner|sockets|firewall|audit)
            sudo /home/moskov/Desktop/Moskov/Ciberseguridad/01_Scripts/go/netaudit/netaudit "$cmd" "$@"
            ;;
        help|-h|--help|"")
            /home/moskov/Desktop/Moskov/Ciberseguridad/01_Scripts/go/netaudit/netaudit help
            ;;
        *)
            echo "[!] Comando desconocido: $cmd"
            echo "    Usa: netscan help"
            ;;
    esac
}

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
