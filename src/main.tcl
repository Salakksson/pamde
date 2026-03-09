#!/usr/bin/env tclsh

source "managers.tcl"

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

proc main {} {
	#source $config_file

	puts [ bash {
		echo $1
		echo $2
		echo $3
	} arg1 arg2 arg3 ]
}

main
