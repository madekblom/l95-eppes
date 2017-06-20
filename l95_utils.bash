#!/bin/bash

# Contains: emember_makefile, generate_l95_namelist, generate_l95truth_namelist
#
# emember_makefile writes the Makefile corresponding to a single eppes run
#
# NOTE: This sub-makefile becomes part of the main Makefile at the RUNDIR root.
#       The current directory context 'CURDIR', in which Make interprets this
#       sub-makefile is 'DATA', not the sub-directory in which this
#       sub-makefile is, 'DATA/*'.

# Lorenz 95 exe and true data 

L95_EXE=
L95_DATA=${DEFDIR}/truth/l95truth40.dat # l95 true data, generated before-hand
L95_TIME=${DEFDIR}/truth/l95truetime.dat # l95 time vector corr. to true data

SCORES_FUN=${DEFDIR}/scores.py # calculates scores for each ensemble member

SET_PERT_VAL=${DEFDIR}/set_pert_values.py # reads analysis data and adds perturbation (s0_sigma)


emember_makefile () {
    local currdir="day${1}/emember${2}"
    local prevdir="day$(( $1 - 1 ))/eppes"
    local andir="day${1}/analysis"
    cat > "${currdir}/Makefile" <<EOF

${currdir}/scores_pert.dat : ${SCORES_FUN} ${L95_DATA} ${currdir}/l95out.dat ${L95_TIME} 
	cd ${currdir}; python ${SCORES_FUN} ${L95_DATA} ${DATA}/${currdir}/l95out.dat ${L95_TIME} $((${T_DAY}+${T_OUT}*(${1}-1) ))

${currdir}/l95out.dat : ${L95_NML} ${currdir}/gupars.dat ${currdir}/s0file.dat ${L95_EXE}
	cd ${currdir}; ${L95_EXE} ${L95_NML}

${currdir}/gupars.dat : ${prevdir}/sampleout.dat
	sed -n '${2}p' \$< > \$@

${currdir}/s0file.dat : ${andir}/s0file.dat ${SET_PERT_VAL}
	cd ${currdir} ; python ${SET_PERT_VAL} ${DATA}/${andir}/s0file.dat ${S0_SIGMA}

EOF

}

generate_l95_namelist () {
    local filename="$1"
    cat > "${DATA}/${filename}" <<EOF
&lorenz95pars
 K = ${PARS_K}   
 J = 0    
 F = ${PARS_F}
 dt = ${PARS_DT}
 dout = ${PARS_DOUT}  
 t0 = ${PARS_T0}  
 t1 = ${PARS_T1} 
 guparfile = 'gupars.dat' 
 etaparfile = ${PARS_ETATPARFILE}          
 s0file = 's0file.dat' 
 s0sigma = 0      
/
EOF
}

generate_l95truth_namelist () {
    local filename="$1"
    cat > "${DATA}/${filename}" <<EOF
&lorenz95pars
 K = ${PARS_K}  
 J = ${PARS_J}    
 F = ${PARS_F}  
 b = ${PARS_B} 
 c = ${PARS_C} 
 h = ${PARS_H}  
 Fy = ${PARS_FY}
 dt = ${PARS_DT} 
 guparfile = '' 
 etaparfile = ''          
 s0file = 'l95s0.dat'     
/
EOF
}
