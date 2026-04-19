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
		bash {
			pacman -S $1
		} $packages
	}

	proc update {} {
		bash {
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
		bash {
			dnf install $1
		} $packages
	}

	proc update {} {
		bash {
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

	proc query-orphan {} {
		bash {
			pkg autoremove -n
		}
	}
}

namespace eval managers {
	proc query-explicit {manager} {
		${manager}::query-explicit
	}
}
