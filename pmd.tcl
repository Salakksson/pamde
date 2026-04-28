#!/usr/bin/env tclsh

# dictionary of all packages
set pkgs ""
# current package being created
set pkg ""
# name of current package
set pkg_name ""
# list of valid fields for a package
set fields ""
# interpreter for parsing packages
set safe_interp ""

# unpacks struct into separate variables
proc unpack {struct args} {
	if {[llength $struct] != [llength $args]} {
		error "cannot unpack struct:\n$struct\ninto:\n$args"
	}
	for {set i 0} {$i < [llength $args]} {incr i} {
		set varname [lindex $args $i]
		set value [lindex $struct $i]
		upvar 1 $varname $varname
		set $varname $value
	}
}

proc pkg_field_var {name} {
	global fields
	lappend fields $name

	proc api_${name} {args} [format {
		upvar ::pkg pkg
		upvar ::pkg_name pkg_name

		if {[llength $args] != 1} {
			error "Misformatted $pkg_name.%s"
			pkg_fail $pkg_name
			return;
		}

		if {[dict exists $pkg %s]} {
			error "Redefining $pkg_name.%s"
			pkg_fail $pkg_name
			return;
		}

		set value [lindex $args 0]
		dict set pkg %s $value

	} $name $name $name $name]
}

proc pkg_field_dict {name} {
	global fields required_fields
	lappend fields $name

	proc api_${name} {args} [format {
		upvar ::pkg pkg
		upvar ::pkg_name pkg_name

		if {[llength $args] != 2} {
			error "Misformatted $pkg_name.%s"
			pkg_fail $pkg_name
			return;
		}

		set key [lindex $args 0]
		set new_value [lindex $args 1]

		if {![dict exists $pkg %s $key]} {
			dict set pkg %s $key ""
		}

		set value [dict get $pkg %s $key]
		lappend value $new_value
		dict set pkg %s $key $value

	} $name $name $name $name $name $name $name]
}

proc pkg_validate {pkg} {
	set valid true
	set errs ""

	# For a package to be valid it must do SOMETHING
	# A package can do one of the following to be valid:
	# Build (contains build, install, uninstall, makedepends)
	# Offload to a package manager (contains from-repo)
	# Have a non-empty depends list

	set is_buildable ""
	set is_offloaded ""
	set has_depends ""

	if {![dict exists $pkg description]} {
		set valid false
		lappend errs "missing description"
	}
	# check if package has a valid build recipe

	set build_fields "build install uninstall makedepends"

	set missing ""
	set contains ""

	foreach field $build_fields {
		if {[dict exists $pkg $field]} {
			lappend contains $field
		} else {
			lappend missing $field
		}
	}

	if {[llength $missing] != 0 && [llength $contains] != 0} {
		set valid false
		lappend errs "missing fields {$missing} for build"
	}

	set is_buildable [expr {[llength $missing] == 0}]

	# check if package is offloaded

	set is_offloaded [dict exists $pkg from-repo]

	# check if package has depends

	set has_depends [dict exists $pkg depends]

	if {!($is_buildable || $is_offloaded || $has_depends)} {
		set valid false
		lappend errs "not buildable, not offloaded and has no depends"
	}

	# TODO: VALIDATE ANY FIELDS WHICH MUST BE VALID
	return [list $valid $errs $is_buildable $is_offloaded];
}

proc api_pkg {name block} {
	global pkgs pkg pkg_name fields safe_interp
	if {$pkg_name ne ""} {
		error "Nested package $name inside $pkg_name"
		pkg_fail $pkg_name
		return;
	}
	if {[dict exists $pkgs $name]} {
		error "TODO: handle package already exists"
		pkg_fail $name
		return;
	}
	set pkg_name $name

	set pkg ""

	$safe_interp eval $block

	set validity [pkg_validate $pkg]
	set is_valid [lindex $validity 0]
	set errors [lindex $validity 1]
	set buildable [lindex $validity 2]

	if {!$is_valid} {
		set msg "Package '$pkg_name' is invalid for the reason(s):";

		foreach err $errors {
			set msg "$msg\n - $err"
		}
		error $msg
	}

	foreach field "depends makedepends description" {
		if {![dict exists $pkg $field]} {
			dict set pkg $field ""
		}
	}

	dict set pkgs $pkg_name $pkg

	set pkg_name ""
}

proc api_source {file} {
	source_safe $file
}

proc api_source_web {} {
	error "TODO: source_web"
}

proc source_safe {file} {
	global safe_interp
	set fp [open $file]
	set src [read $fp]
	close $fp

	$safe_interp eval $src

	# append changes to db once i have decided on format
}

proc dict-getdef {args} {
	global pkgs
	set default [lindex $args end]
	set args [lrange $args 0 end-1]

	if {[dict exists {*}$args]} {
		return [dict get {*}$args]
	} else {
		puts "using default value {$default}"
		return $default
	}
}

proc get_package {pkg_name} {
	global pkgs
	return [dict-getdef $pkgs $pkg_name ""]
}

proc pkg_deps {pkg_name} {
	set pkg [get_package $pkg_name]
	if {$pkg eq ""} {
		return [list 0 true "package $pkg_name does not exist"]
	}

	set depends [dict-getdef $pkg depends ""]
	set makedepends [dict-getdef $pkg makedepends ""]
	set root_deps [list {*}$depends {*}$makedepends]

	set failed false
	set errs ""
	foreach dep $root_deps {
		# set result [pkg_deps $dep]
		# set r_deps [lindex $result 0]
		# set r_failed [lindex $result 1]
		# set r_errs [lindex $result 2]
		unpack [pkg_deps $dep] r_deps r_failed r_errs

		lappend root_deps {*}$r_deps
		if {$r_failed} {
			set failed true
			lappend errs {*}$r_errs
		}
	}

	return [list $root_deps $failed $errs]
}

proc pkg_install_raw {pkg_name} {
	set failed false
	set errs ""

	set pkg [get_package $pkg_name]

	cd ./$pkg_name
	exec [dict get $pkg build]
	cd ./$pkg_name
	exec [dict get $pkg install]

	return [list $failed $errs]
}

proc pkg_install {pkg_name} {
	unpack [pkg_deps $pkg_name] deps failed errs
	if {$failed} {
		error "cannot find dependencies of $pkg_name:\n$errs"
	}

	foreach dep $deps {
		unpack [pkg_install_raw $dep] r_failed r_errs
		if {$r_failed} {
			set failed true
			lappend errs {*}$r_errs
		}
	}

	unpack [pkg_install_raw $pkg_name] r_failed r_errs
	if {$r_failed} {
		set failed true
		lappend errs {*}$r_errs
	}

	return [list $failed $errs]
}

proc init {} {
	global safe_interp fields

	pkg_field_dict from-repo
	pkg_field_var description
	pkg_field_var makedepends
	pkg_field_var depends
	pkg_field_var provides
	pkg_field_var build
	pkg_field_var install
	pkg_field_var uninstall

	set safe_interp [interp create -safe]

	foreach cmd [interp eval $safe_interp {info commands}] {
		interp hide $safe_interp $cmd
	}

	set api "pkg source source_web"

	foreach field [concat $fields $api] {
		interp alias $safe_interp $field {} api_${field}
	}

	source_safe devenv/pkgs.tcl
}

init

puts [pkg_deps pamde]


pkg_install pamde
