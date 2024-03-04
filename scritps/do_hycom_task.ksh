#! /bin/ksh
#
# This is the master script to run a hycom application. No input required.
# Just run this script.
#
# Written by Leonardo Carvalho - LABESUL/UFES
#

grep scpt_dir hycom_domain.input		| cut -d":" -f2	| read scpt_dir
grep hycom_root_dir hycom_domain.input		| cut -d":" -f2	| read hycom_root_dir
grep max_domain hycom_domain.input		| cut -d":" -f2	| read max_domain
grep start_date hycom_domain.input		| cut -d":" -f2	| read start_date
grep end_date hycom_domain.input		| cut -d":" -f2	| read end_date

cd ${scpt_dir}


for grid_id in {2..$max_domain};do
	grep d0${grid_id}_name hycom_domain.input	| cut -d":" -f2 | read domain_name
	grep run_mode hycom_domain.input         	| cut -d":" -f2 | read run_mode
	grep d0${grid_id}_kdm hycom_domain.input 	| cut -d":" -f2 | read kdm
	grep d0${grid_id}_sig hycom_domain.input 	| cut -d":" -f2 | read sigma
	
	# 1) Build the bathymetry for the desired domain
	
	if [[ ! -e ${hycom_root_dir}/${domain_name}/topo/regional.depth.a ]];then
		echo ${hycom_root_dir}/${domain_name}/topo/regional.depth.a
		${scpt_dir}/do_hycom_grid.ksh ${grid_id}
	fi

	# 2) Compile the model for current application (already checks if grid properties has change)

	${scpt_dir}/do_hycom_compilation.ksh ${grid_id} ${kdm} ${sigma}

	# 3) Look whether atmosphecial data is compatible with time and space 
#	${scpt_dir}/get_atm_data.ksh ${start_date} ${end_date}

	# 4) Check if the simulation is climatological or actual run and run the proper task

	case ${run_mode} in clim)
		grep nyears hycom_domain.input		| cut -d":" -f2	| nyears
		${scpt_dir}/do_clim_task.ksh ${grid_id} ${kdm} ${sigma} ${nyears}			#call run clim task!
	;;
		 
			 actual)
		grep start_date hycom_domain.input		| cut -d":" -f2	| start_date
		grep end_date hycom_domain.input		| cut -d":" -f2	| end_date
		${scpt_dir}/do_actual_task.ksh ${grid_id} ${kdm} ${sigma} ${start_date} ${end_date} 	#call actual task!
	;;
	esac
done
