#!/bin/bash

EPSDIR=
DEFDIR=$(dirname $(readlink -f "${BASH_SOURCE[0]}"))
RUNDIR=$(readlink -f run-eppes-l95)
DATA=${RUNDIR}/data

# The number of the experiment days and the number of the ensemble members

DAY=2
ENS=10

# Standard deviation for input files

S0_SIGMA=0.1 # standard deviation of perturbation noise 
AN_SIGMA=0.05 # standard deviation of analysis noise

# These two values are needed for scores calculation (not the most beautiful..)

T_DAY=160 # First day ends at this time (multiplied by 100)=(DOUT+T1)*100
T_OUT=40 # time*100 between ensemble launches = DOUT*100
 
## Lorenz95 parameters

PARS_K=40 # no. of slow states
PARS_J=8 # no. of fast states
PARS_F=10.0 # forcing term
PARS_FY=8.0 # forcing term for fast variables
PARS_B=10.0
PARS_C=10.0
PARS_H=1.0
PARS_DT=0.0025 # integration time step
PARS_DOUT=0.4 # output time step
PARS_T0=0.0 # integration start
PARS_T1=1.2 # integration end
PARS_ETAPARFILE="" # stochastic parameters

#####

source eppes_utils.bash
source l95_utils.bash

mkdir -p ${DATA}
pushd $_ > /dev/null

# generate namelists
generate_eppes_namelist eppesconf_run.nml 0
generate_eppes_namelist eppesconf_init.nml 1
generate_l95_namelist lorenz95.nml 
# generate_l95truth_namelist lorenz95truth.nml 

# set variables:
EPPES_INIT=${DATA}/eppesconf_init.nml 
EPPES_RUN=${DATA}/eppesconf_run.nml 
L95_NML=${DATA}/lorenz95.nml 

# Day0 -- Run Eppes initialization, only

pushd ${DATA} > /dev/null

mkdir -p day0/eppes
cp ${DEFDIR}/eppes_init/*.dat day0/eppes
eppes_init_makefile day0/eppes

# Each Day > 0: Create work structure

for j in $(seq 1 $DAY) ; do
    for i in $(seq 1 $ENS) ; do
	# i=$(printf "%03d" $i)
        mkdir -p day${j}/emember${i}
	emember_makefile ${j} ${i}
    done
    mkdir -p day${j}/{eppes,analysis}
    eppes_makefile day${j}/eppes day$(( $j - 1 ))/eppes day${j} ${j}
done

popd > /dev/null

submakefiles=$(find day* -name Makefile -printf ' \\\n  %p')

cat > Makefile <<EOF
.PHONY: all
all: day${DAY}/eppes/sampleout.dat
include ${submakefiles}
EOF
