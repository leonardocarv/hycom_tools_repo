#! /bin/ksh
#
# This program interpolates the hycom climotology to the hycom grid/depth
# Written by Leonardo Carvalho 
#
grid_id=$1		# Domain indice (1 for father, 2 for first nested...)
sigma=$2      		# Flag to sigma target (0 for sigma0 or 2 for sigma2)

grep all_path hycom_domain.input	| cut -d":" -f2	| read all_path
grep hycom_root_dir hycom_domain.input	| cut -d":" -f2	| read hycom_root_dir
grep d0${grid_id}_name hycom_domain.input | cut -d":" -f2 | read domain_name

run_path=${hycom_root_dir}/${domain_name}/run

if [[ ! -d ${run_path}/clim ]];then
	mkdir -p ${run_path}/clim
fi

cd ${run_path}/clim

ln -sf ${all_path}/relax/src/z_woa13 ${run_path}/clim
ln -sf ${hycom_root_dir}/${domain_name}/topo/regional.grid.a ${run_path}/clim
ln -sf ${hycom_root_dir}/${domain_name}/topo/regional.grid.b ${run_path}/clim

for i in {1..12};do
	printf "%02d\n" $i | read mm

	export CDF_TEMP=tm${mm}.nc
	export CDF_SALN=sm${mm}.nc

	ln -sf ${hycom_root_dir}/data/clim/WOA18/WOA18_PTEMP_m${mm}.nc ${run_path}/clim/tm${mm}.nc
	ln -sf ${hycom_root_dir}/data/clim/WOA18/WOA18_SALT_m${mm}.nc ${run_path}/clim/sm${mm}.nc

	export FOR010A=fort.10A
	export FOR011A=fort.11A
	export FOR012A=fort.12A

	touch fort.10 fort.10A fort.11 fort.11A fort.12 fort.12A
	\rm fort.10 fort.10A fort.11 fort.11A fort.12 fort.12A

	cat<<EOF> fort.temp
 &AFTITL
  CTITLE = '1234567890123456789012345678901234567890',
  CTITLE = 'WOA18 monthly',
 /
 &AFFLAG
  ICTYPE =   3,  !1=Sigma-0+T; 2=Sigma-0+S; 3=T+S;
  SIGVER =   ${sigma},  !0=sig0; 2=sig2;
  INTERP =   1,
  ITEST  =  300,
  JTEST  =  300,
  MONTH  = $mm,

/
EOF

#  ICTYPE =   4,
#  KSIGMA =   ${sigma},
#  INTERP =   1,
#  ITEST  =  40,
#  JTEST  =  17,
#  MONTH  = $mm,
# /
#EOF

	${run_path}/clim/z_woa13 < fort.temp

	mv fort.10  temp_sig${sigma}_m${mm}.b
	mv fort.10A temp_sig${sigma}_m${mm}.a
	mv fort.12  dens_sig${sigma}_m${mm}.b
	mv fort.12A dens_sig${sigma}_m${mm}.a

# Optional output (I do not know where use it)
	mv fort.11  saln_sig${sigma}_m${mm}.b
	mv fort.11A saln_sig${sigma}_m${mm}.a

	\rm fort*
done

\rm z_woa13 regional*

