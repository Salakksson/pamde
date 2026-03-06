set config_file "/usr/local/etc/pamde.tcl"
# temporary
set config_file "./config.tcl"

proc help {} {
	puts "TODO: add help functionality"
}

proc packages {list} {
	set local_packages [regexp -all -inline {\S+} $list]
	uplevel "set conf_packages \"$local_packages\""
}

proc bash {code args} {
	# set args
	if {[llength $args] != 0} {
	puts "Iterating over [llength $args] extra arguments:"
		set index 1
		foreach extra $args {
			puts "  Argument $index: $extra"
			set name "arg$index"
			puts $name
			incr index
		}
	}
	run_bash $code
	return ""
}


proc main {} {
	help
	#source $config_file

	bash {
		echo wow1
		echo wow2
		echo wow3
	} wow1=you wow2=are wow3=gay
}

main
