#!/bin/bash

# Contains functions: eppes_makefile, eppes_init_makefile, generate_eppes_namelist
#
# NOTE: The same as for emember_makefile found in l95_utils
EPPES_EXE=

# reads true data and adds analysis error (an_sigma)

OBS_ERROR=${DEFDIR}/set_init_values.py 

eppes_makefile () {
    local currdir="${1}"
    local prevdir="${2}"
    local andir="${3}/analysis"
    local iday="${4}"
    local from_prev_day=(
        bounds.dat mufile.dat nfile.dat sigfile.dat wfile.dat)
    local cdirs=($(ls -w 0 -vd ${3}/emember*))
    cat > "${currdir}/Makefile" <<EOF

${currdir}/sampleout.dat : ${EPPES_RUN} ${from_prev_day[@]/#/${currdir}/} ${currdir}/scores.dat ${currdir}/oldsample.dat ${EPPES_EXE}
	cd ${currdir}; ${EPPES_EXE} ${EPPES_RUN}

${currdir}/oldsample.dat : ${prevdir}/sampleout.dat
	cp ${prevdir}/sampleout.dat ${currdir}/oldsample.dat

${from_prev_day[@]/#/${currdir}/} : ${from_prev_day[@]/#/${prevdir}/} ${prevdir}/sampleout.dat
	cp ${from_prev_day[@]/#/${prevdir}/} ${currdir}/

${currdir}/scores.dat : ${cdirs[@]/%//scores_pert.dat}
	cat ${cdirs[@]/%//scores_pert.dat} > \$@

${andir}/s0file.dat : ${L95_DATA} ${OBS_ERROR}
	cd ${andir} ; python ${OBS_ERROR} \$< ${4} ${AN_SIGMA}

EOF
}

eppes_init_makefile () {
    local outdir="$1"
    cat > "${outdir}/Makefile" <<EOF

${outdir}/sampleout.dat : \$(addprefix ${outdir}/,bounds.dat mufile.dat nfile.dat sigfile.dat wfile.dat) ${EPPES_INIT} ${EPPES_EXE}
	cd ${outdir}; ${EPPES_EXE} ${EPPES_INIT}

EOF
}

generate_eppes_namelist () {
    local filename="$1"
    local sampleonly="$2"
    cat > "${DATA}/${filename}" <<EOF
&eppesconf
 sampleonly = ${sampleonly}
 nsample    = ${ENS}
 mufile    = 'mufile.dat'
 sigfile   = 'sigfile.dat'
 wfile     = 'wfile.dat'
 nfile     = 'nfile.dat'
 samplein  = 'oldsample.dat'
 sampleout = 'sampleout.dat'
 scorefile = 'scores.dat'
 boundsfile = 'bounds.dat'
/
EOF
}
