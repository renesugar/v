// Copyright (c) 2019-2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module builder

import os

// parsed cflag
struct CFlag {
	mod   string // the module in which the flag was given
	os    string // eg. windows | darwin | linux
	name  string // eg. -I
	value string // eg. /path/to/include
}

pub fn (c &CFlag) str() string {
	return 'CFlag{ name: "$c.name" value: "$c.value" mod: "$c.mod" os: "$c.os" }'
}

// get flags for current os
fn (v &Builder) get_os_cflags() []CFlag {
	mut flags := []CFlag
	mut ctimedefines := []string
	if v.pref.compile_defines.len > 0 {
		ctimedefines << v.pref.compile_defines
	}
	for flag in v.table.cflags {
		if flag.os == '' || (flag.os == 'linux' && v.pref.os == .linux) || (flag.os == 'darwin' &&
			v.pref.os == .mac) || (flag.os == 'freebsd' && v.pref.os == .freebsd) || (flag.os == 'windows' &&
			v.pref.os == .windows) || (flag.os == 'mingw' && v.pref.os == .windows && v.pref.ccompiler !=
			'msvc') || (flag.os == 'solaris' && v.pref.os == .solaris) {
			flags << flag
		}
		if flag.os in ctimedefines {
			flags << flag
		}
	}
	return flags
}

fn (v &Builder) get_rest_of_module_cflags(c &CFlag) []CFlag {
	mut flags := []CFlag
	cflags := v.get_os_cflags()
	for flag in cflags {
		if c.mod == flag.mod {
			if c.name == flag.name && c.value == flag.value && c.os == flag.os {
				continue
			}
			flags << flag
		}
	}
	return flags
}

// format flag
fn (cf &CFlag) format() string {
	mut value := cf.value
	if cf.name in ['-l', '-Wa', '-Wl', '-Wp'] && value.len > 0 {
		return '${cf.name}${value}'.trim_space()
	}
	// convert to absolute path
	if cf.name == '-I' || cf.name == '-L' || value.ends_with('.o') {
		value = '"' + os.real_path(value) + '"'
	}
	return '$cf.name $value'.trim_space()
}

// TODO: implement msvc specific c_options_before_target and c_options_after_target ...
fn (cflags []CFlag) c_options_before_target_msvc() string {
	return ''
}

fn (cflags []CFlag) c_options_after_target_msvc() string {
	return ''
}

fn (cflags []CFlag) c_options_before_target() string {
	// -I flags, optimization flags and so on
	mut args := []string
	for flag in cflags {
		if flag.name != '-l' {
			args << flag.format()
		}
	}
	return args.join(' ')
}

fn (cflags []CFlag) c_options_after_target() string {
	// -l flags (libs)
	mut args := []string
	for flag in cflags {
		if flag.name == '-l' {
			args << flag.format()
		}
	}
	return args.join(' ')
}

fn (cflags []CFlag) c_options_without_object_files() string {
	mut args := []string
	for flag in cflags {
		if flag.value.ends_with('.o') || flag.value.ends_with('.obj') {
			continue
		}
		args << flag.format()
	}
	return args.join(' ')
}

fn (cflags []CFlag) c_options_only_object_files() string {
	mut args := []string
	for flag in cflags {
		if flag.value.ends_with('.o') || flag.value.ends_with('.obj') {
			args << flag.format()
		}
	}
	return args.join(' ')
}
