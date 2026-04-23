puts "beginning of config"

pamde::set-manager pkg
pamde::verbosity 3

switch [pamde::hostname] {
	default {

	}
}

pamde::want {
}

puts "end of config"
