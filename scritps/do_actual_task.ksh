#! /bin/ksh
#
# This program starts a hycom actual run (not climatology)
# Written by Leonardo Carvalho
#
#
grid_id=$1
kdm=$2
sigma=$3
idate=$4
fdate=$5

grep all_path hycom_domain.input		| cut -d":" -f2	| read all_path
grep scpt_dir hycom_domain.input		| cut -d":" -f2	| read scpt_dir
grep hycom_root_dir hycom_domain.input		| cut -d":" -f2	| read hycom_root_dir
grep d0${grid_id}_name hycom_domain.input	| cut -d":" -f2 | read domain_name
grep mpi_bin_path hycom_domain.input		| cut -d":" -f2	| read mpi_bin_path

run_path=${hycom_root_dir}/${domain_name}/run
scratch_path=${run_path}/scratch
restart_path=${run_path}/restart


# Calculate the time by means of hycom reference (1900123100)
date --date="19001231 00:00:00" +%s	| read t
date --date="$idate 00:00:00" +%s 	| read i
date --date="$fdate 00:00:00" +%s	| read j

t_start=0
t_max=0
dt=86400
t_aux=$t

while (( $i >= $t_aux ));do
	(( t_start += 1 ))
	(( t_aux += $dt ))
done
t_aux=$t
while (( $j >= $t_aux ));do
	(( t_max += 1 ))
	(( t_aux += $dt ))
done
if [[ ! -d ${run_path}/clim ]];then
	${scpt_dir}/do_levitus_sig.ksh ${grid_id} ${sigma}
	${scpt_dir}/do_relax.ksh ${grid_id} ${kdm} ${sigma}
fi
if [[ ! -d ${scratch_path} ]];then
	mkdir -p ${scratch_path}
fi

# Check if there is restart for the actual run, if not do a climatological run
# and change parameters to run the experiment (five years as climatology)

if [[ ! -d ${restart_path} ]];then
	${scpt_dir}/do_clim_task.ksh $grid_id $kdm $sigma 5		# Run climatological experiment
	newline="RESTART2: nstep,dtime,thbase =        43200         $t_start         25.0000000000000"
	cat ${restart_path}/restart_out.b | sed -n 2p | read aux
	cat ${restart_path}/restart_out.b | sed "s&$aux&$newline&g" > ${restart_path}/restart_out.b.temp
	mv ${restart_path}/restart_out.b.temp ${restart_path}/restart_out.b	
fi

# Make actual atmospheric data

${scpt_dir}/do_atm_forcing.ksh ${grid_id} actual $idate $fdate 		#the date do not change any property in clim option

cd ${scratch_path}

touch arch.dummy
\rm -r *

ln -sf ${scpt_dir}/hycom_domain.input ${scratch_path}

cat <<EOF> ${scratch_path}/ports.input
  0     'nports' = number of boundary port sections
 30.0   'pefold' = port transport e-folding time in days
EOF


# Check if the simulation is nested and call do_nest_task.ksh if so

if [[ ${grid_id} -gt 1 ]];then
	\rm ports.input
	${scpt_dir}/do_nest_task.ksh ${grid_id} $idate $fdate
	$scpt_dir/do_blkdat.ksh ${grid_id} $kdm 3 $sigma nest
	mv ${scratch_path}/nest/ports.input ${scratch_path}
	ln -sf ${run_path}/clim/relax.rmu.a  ${scratch_path}/nest/rmu.a
	ln -sf ${run_path}/clim/relax.rmu.b  ${scratch_path}/nest/rmu.b
else
	$scpt_dir/do_blkdat.ksh ${grid_id} $kdm 3 $sigma
fi

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
# restart files
ln -sf ${run_path}/restart/restart_out.a ${scratch_path}/restart_in.a
ln -sf ${run_path}/restart/restart_out.b ${scratch_path}/restart_in.b
# Rivers (check existence)
if [[ -d ${run_path}/rivers ]];then
	ln -sf ${run_path}/rivers/forcing.rivers.a ${scratch_path}
	ln -sf ${run_path}/rivers/forcing.rivers.b ${scratch_path}
fi

# Check if mpd is running
ps -ef | grep -v grep | grep mpd | wc -l | read mpd_aux

if [[ ${mpd_aux} < 1 ]];then
	${mpi_bin_path}/mpd &
	sleep 1
fi

# make needed files

touch   flxdp_out.a flxdp_out.b
mv flxdp_out.a flxdp_old.a
mv flxdp_out.b flxdp_old.b

touch   ovrtn_out
mv ovrtn_out ovrtn_old

echo "    ${t_start}   ${t_max}     false    false" > limits

# Run the model
${mpi_bin_path}/mpirun -np 4 ${scratch_path}/hycom

# move the results and restarts to the results dir
mv archv* ${run_path}/results
mv restart_out* ${run_path}/restart
