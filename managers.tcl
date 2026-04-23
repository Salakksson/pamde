namespace eval pacman {
	proc query-explicit {} {
		bash {
			pacman -Qqe
		}
	}

	proc query-all {} {
		bash {
			pacman -Qq
		}
	}

	proc query-orphan {} {
		bash {
			pacman -Qdtq
		}
	}

	proc install {packages} {
		bash-sudo {
			pacman -S $1
		} $packages
	}

	proc update {} {
		bash-sudo {
			pacman -Syyu
		}
	}
}

namespace eval dnf {
	proc query-explicit {} {
		bash {
			dnf repoquery --userinstalled --qf "%{name} "
		}
	}

	proc query-all {} {
		bash {
			dnf repoquery --userinstalled --qf "%{name} "
		}
	}

	proc query-orphan {} {
		bash {
			dnf repoquery --unneeded --qf "%{name} "
		}
	}

	proc install {packages} {
		bash-sudo {
			dnf install $1
		} $packages
	}

	proc update {} {
		bash-sudo {
			dnf upgrade
		}
	}
}

namespace eval pkg {
	proc query-explicit {} {
		bash {
			pkg query -e '%a = 0' '%n'
		}
	}

	proc query-all {} {
		bash {
			pkg query '%n'
		}
	}

	proc query-orphan {} {
		bash {
			pkg query -e '%a = 1 && %?r = 0' '%n'
		}
	}

	proc install {packages} {
		bash-sudo {
			pkg install $1
		} $packages
	}

	proc update {} {
		bash-sudo {
			pkg upgrade
		}
	}

}

namespace eval managers {
	proc query-explicit {manager} {
		${manager}::query-explicit
	}
}
