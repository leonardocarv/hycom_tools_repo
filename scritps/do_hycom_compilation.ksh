#! /bin/ksh
#
# This script allows the user to compile the hycom model quickly.
# The user must specify the grid id and sigma.This program
# checks if the is any executable and if this executable is 
# compatible with the horizontal and vertical grid.
#
# Written by Leonardo Carvalho
#

grid_id=$1
kdm=$2
sigma=$3

grep hycom_root_dir hycom_domain.input		| cut -d":" -f2	| read hycom_root_dir
grep d0${grid_id}_name hycom_domain.input	| cut -d":" -f2 | read domain_name
grep mpi_bin_path hycom_domain.input		| cut -d":" -f2	| read mpi_bin_path

src_path=${hycom_root_dir}/${domain_name}/src
topo_path=${hycom_root_dir}/${domain_name}/topo

if [[ ! -d ${src_path} ]];then 
	mkdir -p ${src_path}
	cd ${src_path}
	cp -f ${hycom_root_dir}/src/hycom_src_mpi.tar ${src_path}
	tar -xvf hycom_src_mpi.tar
fi

cd ${src_path}

# Check if dimensions.h is compatible with the grid (I'll look for idm,jdm,ibig,jbig,kdm,m,n)

grep "(itdm" dimensions.h | cut -d"=" -f2 | cut -d"," -f1 | read ditdm
grep "(itdm" dimensions.h | cut -d"=" -f3 | cut -d"," -f1 | read djtdm
grep "(itdm" dimensions.h | cut -d"=" -f4 | cut -d")" -f1 | read dkdm

grep "(idm" dimensions.h  | cut -d"=" -f2 | cut -d"," -f1 | read dibig
grep "(idm" dimensions.h  | cut -d"=" -f3 | cut -d")" -f1 | read djbig

grep "(iqr" dimensions.h  | cut -d"=" -f2 | cut -d"," -f1 | read diqr
grep "(iqr" dimensions.h  | cut -d"=" -f3 | cut -d")" -f1 | read djqr

cat ${topo_path}/patch.input | sed -n 2p | read aux

echo $aux | cut -d ' ' -f2 | read n
echo $aux | cut -d ' ' -f3 | read m
echo $aux | cut -d ' ' -f4 | read idm
echo $aux | cut -d ' ' -f5 | read jdm
echo $aux | cut -d ' ' -f6 | read ibig
echo $aux | cut -d ' ' -f7 | read jbig

grep sigver ${src_path}/stmt_fns.h |  read aux_sig
echo $aux_sig | cut -c26-26 | read aux_sig

if [[ $ditdm != $idm || $djtdm != $jdm || $kdm != $dkdm || $diqr != $m || $djqr != $n || ${sigma} != ${aux_sig} ]];then
	
	if [[ ${sigma} -eq 2 ]];then
		cp ${src_path}/ALT_CODE/stmt_fns_SIGMA2.h ${src_path}/stmt_fns.h
	fi

	cat dimensions.h | sed -n 9p  | read swap_line1
	cat dimensions.h | sed -n 14p | read swap_line2
	cat dimensions.h | sed -n 19p | read swap_line3
	cat dimensions.h | sed -n 31p | read swap_line4

	newline1="parameter (itdm=$idm,jtdm=$jdm,kdm=$kdm)  ! ATLb2.00"
	newline2="parameter (iqr=$m,jqr=$n)  ! multiple tiles (TYPE=ompi or mpi or shmem)"
	newline3="parameter (idm=$ibig,jdm=$jbig)  ! always works if enough memory"
	newline4="parameter (kknest=$kdm)  ! must be 1 or kdm"
	
	cat ${src_path}/dimensions.h | sed "s&$swap_line1&$newline1&g" |\
				       sed "s&$swap_line2&$newline2&g" |\
				       sed "s&$swap_line3&$newline3&g" |\
				       sed "s&$swap_line4&$newline4&g" > dimensions.h.temp

	mv ${src_path}/dimensions.h.temp ${src_path}/dimensions.h

	# do the compilation
	touch dummy.o dummy.mod hycom
	\rm *.o *.mod hycom
	echo "Compiling HYCOM Model for the $domain_name application..."
	echo " "
	make
else

	echo "The Hycom executable is already compiled for the $domain_name application..."
	echo "Enjoy your simulation!"
fi
