#!/usr/bin/env tclsh

# dictionary of all packages
set pkgs ""
# current package being created
set pkg ""
# name of current package
set pkg_name ""
# list of valid fields for a package
set fields ""

proc info {} {
	global db
	puts "db: $db"
	foreach key $keys {
		set value [dict get $db $key]
		puts "$key: $value"
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
	return [list $valid $errs];
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
	if {!$is_valid} {
		set msg "Package '$pkg_name' is invalid for the reason(s):";

		foreach err $errors {
			set msg "$msg\n - $err"
		}
		error $msg
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

proc pkg_deps_recursive {pkg kinds} {
	global pkgs
	set all_deps ""

	set deps ""
	foreach kind $kinds {
		lappend deps [dict get $pkgs $pkg $kind]
	}
	foreach dep $deps {
		lappend all_deps [pkg_deps_recursive $dep $kinds]
	}
}

proc init {} {
	global safe_interp fields

	# verbose "setting up interpreter"
	set safe_interp [interp create -safe]

	foreach cmd [interp eval $safe_interp {info commands}] {
		interp hide $safe_interp $cmd
	}

	set api "pkg source source_web"

	foreach field [concat $fields $api] {
		interp alias $safe_interp $field {} api_${field}
	}
}

pkg_field_dict from-repo
pkg_field_var description
pkg_field_var makedepends
pkg_field_var depends
pkg_field_var provides

init

source_safe pkglist.tcl

puts "pkgs: $pkgs"

puts [pkg_deps_recursive pamde depends-make]
