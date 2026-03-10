#!/usr/bin/env tclsh

# initial setup bullshit
set MODULES_PATH src
source "${MODULES_PATH}/managers.tcl"

set config_file "/usr/local/etc/pamde.tcl"
set config_file "./config.tcl"

# TODO:

# original features:
# add/remove
# orphans
# profile
# help
# command line arguments
# make default config
# print diff

# new features:
# containers
# package creation/repos
# source-web
# yay-like ignores


namespace eval pamde {
	variable wanted ""
	variable repos ""
	variable packages ""
	proc want {packages} {
		variable wanted
		lappend wanted {*}$packages
	}

	proc source-repo {repo} {
		variable repos
		lappend repos {*}$repo
	}

	proc package {name values} {
		variable packages
		set packages [dict set $packages $name $values]
	}
}

proc help {} {
	puts "TODO: add help functionality"
}

proc bash {code args} {
	exec bash -s -- {*}$args << $code
}

proc diff {a b} {
	set map {}
	foreach x $b {
		dict set map $x 1
	}

	set a_only {}
	set common {}

	foreach x $a {
		if {[dict exists $map $x]} {
			lappend common $x
			dict unset map $x
		} else {
			lappend a_only $x
		}
	}

	set b_only [dict keys $map]

	return [list $a_only $b_only $common]
}

source $config_file

puts "wanted: ${pamde::wanted}"

set all-packages [diff $pamde::wanted [dnf::query-explicit]]

set remove [lindex ${all-packages} 0]
set add [lindex ${all-packages} 1]

puts "add: $add"
puts "remove: $remove"
