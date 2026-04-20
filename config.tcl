puts "beginning of config"

pamde::set-manager pkg
pamde::verbosity 3

switch [pamde::hostname] {
	default {

	}
}

pamde::want {
	clang
	alacritty
	atuin
	ccls
	dmenu
	drm-kmod
	emacs
	en-freebsd-doc
	feh
	gcc
	gdb
	git
	gpu-firmware-intel-kmod-kabylake
	kitty
	libqalculate
	librewolf
	maim
	mpv
	nerd-fonts
	pavucontrol
	picom
	pipewire
	pkg
	pkgconf
	stow
	sudo
	tcl86
	typst
	wget
	wifi-firmware-iwlwifi-kmod-8000
	wireplumber
	xclip
	xinit
	xorg
	xwallpaper
	zathura
	zathura-pdf-poppler
	zoxide
	zsh
}

puts "end of config"
