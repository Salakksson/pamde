#!/usr/bin/env tclsh

pkg tcl {
	description "TCL programming language"
	from-repo dnf "tcl8"
	from-repo pacman "tcl"
}

pkg pamde {
	description "I wonder?"
	makedepends {}
	depends {tcl}

	provides {pamde}

	build {

	}

	install {
		bash {
			touch pamde.test
		}
	}

	uninstall {
		bash {
			rm pamde.test
		}
	}
}

