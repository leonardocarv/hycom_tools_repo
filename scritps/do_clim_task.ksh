#! /bin/ksh
#
# This program starts a hycom climatological run
# Written by Leonardo Carvalho - LABESUL/UFES
#
grid_id=$1
kdm=$2
sigma=$3
nyears=$4

grep all_path hycom_domain.input	| cut -d":" -f2	| read all_path
grep scpt_dir hycom_domain.input	| cut -d":" -f2	| read scpt_dir
grep hycom_root_dir hycom_domain.input	| cut -d":" -f2	| read hycom_root_dir
grep max_domain hycom_domain.input	| cut -d":" -f2	| read max_domain
grep d0${grid_id}_name hycom_domain.input	| cut -d":" -f2 | read domain_name
grep mpi_bin_path hycom_domain.input	| cut -d":" -f2	| read mpi_bin_path

run_path=${hycom_root_dir}/${domain_name}/run
scratch_path=${run_path}/scratch

# Make the relax files if needed

if [[ ! -d ${run_path}/clim ]];then
	${scpt_dir}/do_levitus_sig.ksh ${grid_id} ${sigma}
	${scpt_dir}/do_relax.ksh ${grid_id} ${kdm} ${sigma}
fi
if [[ ! -d ${scratch_path} ]];then
	mkdir -p ${scratch_path}
fi
if [[ ! -d ${run_path}/rivers ]];then
	${scpt_dir}/do_rivers.ksh ${grid_id}
fi

# Make climatological atmospheric data (always will be done, as atmospheric data
# may change for an actual run)

${scpt_dir}/do_atm_forcing.ksh ${grid_id} clim 19001231 19001231 		#the date do not change any property in clim option

cd ${scratch_path}

touch arch.dummy
\rm *.*

ln -sf ${scpt_dir}/hycom_domain.input ${scratch_path}

cat <<EOF> ${scratch_path}/ports.input
  0     'nports' = number of boundary port sections
 30.0   'pefold' = port transport e-folding time in days
EOF


# Link all needed files to run hycom 

# hycom executable
ln -sf ${hycom_root_dir}/${domain_name}/src/hycom ${scratch_path}
# Grid and depth
ln -sf ${hycom_root_dir}/${domain_name}/topo/regional.grid.a  ${scratch_path}
ln -sf ${hycom_root_dir}/${domain_name}/topo/regional.grid.b  ${scratch_path}
ln -sf ${hycom_root_dir}/${domain_name}/topo/regional.depth.a ${scratch_path}
ln -sf ${hycom_root_dir}/${domain_name}/topo/regional.depth.b ${scratch_path}
ln -sf ${hycom_root_dir}/${domain_name}/topo/patch.input      ${scratch_path}
# atmospheric forcing
ln -sf ${run_path}/flux/*   ${scratch_path}
ln -sf ${run_path}/wind/*   ${scratch_path}
ln -sf ${run_path}/surtmp/* ${scratch_path}
# relaxation files
ln -sf ${run_path}/clim/relax.saln.a ${scratch_path}
ln -sf ${run_path}/clim/relax.saln.b ${scratch_path}
ln -sf ${run_path}/clim/relax.temp.a ${scratch_path}
ln -sf ${run_path}/clim/relax.temp.b ${scratch_path}
ln -sf ${run_path}/clim/relax.intf.a ${scratch_path}
ln -sf ${run_path}/clim/relax.intf.b ${scratch_path}
ln -sf ${run_path}/clim/relax.rmu.a  ${scratch_path}
ln -sf ${run_path}/clim/relax.rmu.b  ${scratch_path}
# Rivers (check existence)
if [[ -d ${run_path}/rivers ]];then
	ln -sf ${run_path}/rivers/forcing.rivers.a ${scratch_path}
	ln -sf ${run_path}/rivers/forcing.rivers.b ${scratch_path}
fi
#


$scpt_dir/do_blkdat.ksh ${grid_id} $kdm 0 $sigma

# Check if mpd is running
ps -ef | grep -v grep | grep mpd | wc -l | read mpd_aux

if [[ ${mpd_aux} < 1 ]];then
	${mpi_bin_path}/mpd &
	sleep 1
fi


# limits

ini_year=0
fin_year=360

# loop over the years (for climatogy) - restarting at very year

for y in {1..${nyears}};do

	touch   flxdp_out.a flxdp_out.b
	mv flxdp_out.a flxdp_old.a
	mv flxdp_out.b flxdp_old.b

	touch   ovrtn_out
	mv ovrtn_out ovrtn_old

	echo "    ${ini_year}   ${fin_year}     false    false" > limits
	${mpi_bin_path}/mpirun -np 4 ${scratch_path}/hycom

	if [[ ! -d ${run_path}/restart ]];then
		mkdir -p ${run_path}/restart
	fi

	touch ${run_path}/restart/restart.dummy
	\rm ${run_path}/restart/*

	mv restart_out* ${run_path}/restart

	if [[ ! -d ${run_path}/results ]];then
		mkdir -p ${run_path}/results
	fi
	
	mv archv* ${run_path}/results

	(( ini_year += 360 ))
	(( fin_year += 250 ))

	ln -sf ${run_path}/restart/restart_out.a ${scratch_path}/restart_in.a
	ln -sf ${run_path}/restart/restart_out.b ${scratch_path}/restart_in.b

done

