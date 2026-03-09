set config_file "/usr/local/etc/pamde.tcl"
# temporary
set config_file "./config.tcl"

proc help {} {
	puts "TODO: add help functionality"
}

proc packages {list} {
	puts "packages:" $list
}

proc bash {code args} {
	exec bash -s -- {*}$args << $code
}

bash {
echo $1, $2, $3
} foo bar baz

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


proc main {} {
	#source $config_file

	puts [ bash {
		echo $Z1
		echo $Z2
		echo $Z3
	} arg1 arg2 arg3 ]
}

main
