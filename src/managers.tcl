namespace eval pacman {
	proc query-explicit {} {
		bash {
			pacman -Qqe
		}
	}

	proc query-all {} {
		bash {
			pacman -Qqe
		}
	}

	proc query-orphan {} {
		bash {
			pacman -Qqe
		}
	}

	proc install {pack} {
		bash {
			pacman -S $1
		} $pack
	}

	proc sync {} {
		bash {
			pacman -Syy
		}
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
			dnf repoquery --userinstalled
		}
	}

	proc query-orphan {} {
		bash {
			dnf repoquery --unneeded
		}
	}
}

namespace eval apt {
	proc query-explicit {} {
		bash {
			apt-mark showmanual
		}
	}

	proc query-orphan {} {
		bash {
			apt autoremove --dry-run
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

namespace eval pamde {
	proc query-explicit {manager} {
		${manager}::query-explicit
	}
}
