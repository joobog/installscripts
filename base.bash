#!/bin/bash


function die {
	local l_msg="$1"
	echo "Error ${l_msg}"
	exit 1
}

function exists {
	local l_prog=$1
	command -v $1 >/dev/null 2>&1 || die "Not found ${l_prog}"
}

function extract {
	local l_fn="$1"
	pushd $PWD
	tar -xf "$l_fn" || die "Couldn't extract $l_fn"
	popd 
}

function fetch_svn {
	local l_link="$1"
	pushd $PWD > /dev/null
	if [ -z "$(ls -A ${SRCdir})" ] 
	then
		cd ${SRCdir}
		svn co ${l_link} ${SRCdir} 
	else
		echo "INFO: ${NAME}-${VERSION} is already downloaded"
	fi
	popd > /dev/null
}



function fetch_git {
	local l_link="$1"
	pushd $PWD > /dev/null
	if [ -z "$(ls -A ${SRCdir})" ] 
	then
		cd ${SRCdir}
		git clone ${l_link} ${SRCdir} 
	else
		echo "INFO: ${NAME}-${VERSION} is already downloaded"
	fi
	popd > /dev/null
}



function fetch_http {
	local l_link="$1"
	local l_fn="$(basename ${l_link})"
	
	pushd $PWD > /dev/null
	cd ${SRCdir}
	if [ ! -f "${l_fn}" ] 
	then
		wget ${l_link} -O ${l_fn} 
	else
		echo "INFO: ${NAME}-${VERSION} is already downloaded"
	fi

	extract "${l_fn}"
	popd > /dev/null
}


function fetch_local {
	local l_fn="$1"

	pushd $PWD > /dev/null
	local l_bn="$(basename ${l_fn})"
	if [ ! -e "${l_bn}" ] 
	then
		cd ${SRCdir}
		cp ${l_fn} ./${l_bn}
	else
		echo "INFO: ${NAME}-${VERSION} is already downloaded"
	fi
	extract "${l_bn}"
	popd > /dev/null
}


function build_with {
	local l_build_script="$1"
	pushd $PWD
	cd ${SRCdir}
	$l_build_script
	popd
}

function module_init {
	local l_target_path="$(dirname ${MFILE})"
	local l_target_file="${MFILE}"
	mkdir -p "$l_target_path"
	touch "${l_target_file}"
	echo "#%Module" > "${MFILE}"
	echo "set root $PREFIX" >> "${MFILE}"
}

function add_prepend_path {
	local l_fn="$1"
	local l_varname="$2"
	local l_value="$3"
	local l_line=$(printf "prepend-path %-20s \$root/%s\n" "$l_varname" "$l_value")
	echo "$l_line" >> $l_fn
}

function add_prereq {
	local l_fn="$1"
	local l_value="$2"
	local l_line=$(printf "prereq %-20s\n" "$l_value")
	echo "$l_line" >> $l_fn
}

function module_paths {
	local tokens=("$@")

	for token in ${tokens[@]}; do
		case "$token" in
			bin)
					add_prepend_path $MFILE "PATH" "bin"	
				;;
			bin/binO/Linux.gfortran.64.mpich2.default)
					add_prepend_path $MFILE "PATH" "bin/binO/Linux.gfortran.64.mpich2.default"	
				;;
			sbin)
					add_prepend_path $MFILE "PATH" "sbin"	
				;;
			lib)
					add_prepend_path $MFILE "LD_LIBRARY_PATH" "lib"
					;;
			lib64)
					add_prepend_path $MFILE "LD_LIBRARY_PATH" "lib64"
					;;
			share/man)
					add_prepend_path $MFILE "MANPATH" "share/man"
					;;
			lib/pkgconfig)
					add_prepend_path $MFILE "PKG_CONFIG_PATH" "lib/pkgconfig"
					;;
			lib64/pkgconfig)
					add_prepend_path $MFILE "PKG_CONFIG_PATH" "lib64/pkgconfig"
					;;
			include)
					add_prepend_path $MFILE "C_INCLUDE_PATH" "include"
					add_prepend_path $MFILE "CPLUS_INCLUDE_PATH" "include"
					;;
				*)
					echo "WARNING: Unknown token $token"
		esac
	done
}

function module_load {
	local -a tokens=($@)
	for token in ${tokens[@]}; do
		#module load -f $MPATH/$token
		module load -f $USER/$token
	done
	module list
}

function module_deps {
	local -a tokens=($@)
	for token in ${tokens[@]}; do
		add_prereq $MFILE $USER/$token
	done
}

function auto_module_paths {
	paths=$(find $PREFIX -type d -printf '%P\n')
	module_paths $paths
}

