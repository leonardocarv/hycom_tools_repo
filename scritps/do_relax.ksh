#! /bin/ksh
#
# This program interpolates the hycom climotology to the hycom grid/depth
# Written by Leonardo Carvalho 
#
grid_id=$1		# Domain indice (1 for father, 2 for first nested...)
kdm=$2		# Number of vertical sigma layers (21 or 22)
sigma=$3	# Flag to sigma target (0 for sigma0 or 2 for sigma2)

grep all_path hycom_domain.input	  | cut -d":" -f2	| read all_path
grep hycom_root_dir hycom_domain.input	  | cut -d":" -f2	| read hycom_root_dir
grep max_domain hycom_domain.input	  | cut -d":" -f2	| read max_domain
grep d0${grid_id}_name hycom_domain.input | cut -d":" -f2	| read domain_name
grep d0${grid_id}_dx hycom_domain.input   | cut -d":" -f2	| read dx

run_path=${hycom_root_dir}/${domain_name}/run

if [[ ! -d ${run_path}/clim ]];then
	mkdir -p ${run_path}/clim
fi

cd ${run_path}/clim

#touch   relaxv_sig${sigma} blkdat.input fort.51 fort.51A
#\rm relaxv_sig${sigma} blkdat.input fort.51 fort.51A
touch   relaxi blkdat.input fort.51 fort.51A
\rm relaxi blkdat.input fort.51 fort.51A


ln -sf ${hycom_root_dir}/${domain_name}/topo/regional.grid.a ${run_path}/clim
ln -sf ${hycom_root_dir}/${domain_name}/topo/regional.grid.b ${run_path}/clim
ln -sf ${hycom_root_dir}/${domain_name}/topo/regional.depth.a ${run_path}/clim/fort.51A
ln -sf ${hycom_root_dir}/${domain_name}/topo/regional.depth.b ${run_path}/clim/fort.51
#ln -sf ${all_path}/relax/src/relaxv_sig${sigma} ${run_path}/clim
ln -sf ${all_path}/relax/src/relaxi ${run_path}/clim

cat regional.grid.b | grep idm | cut -c3-9 | read idm
cat regional.grid.b | grep jdm | cut -c3-9 | read jdm

echo "scale=0; $jdm - 250" | bc -l | read jdm_aux

echo "scale=0; $idm - 250" | bc -l | read idm_aux

if [[ $sigma < 1 ]];then
	sigver=1
else
	sigver=2
fi

ln -sf ${run_path}/clim/iso_sigma.b ${run_path}/clim/fort.52
ln -sf ${run_path}/clim/iso_sigma.a ${run_path}/clim/fort.52A

export FOR052A=fort.52A

# Make blkdat.input

cat <<EOF> blkdat.input
Levitus (NOAA World Ocean Atlas 1994) Climatology
  00	  'month ' = month of climatology (01 to 12)
   6	  'sigver' = version of the equation of state
   2      'levtop' = top level of input clim. to use
  22	  'iversn' = hycom version number x10
 010	  'iexpt ' = experiment number x10
   0	  'yrflag' = days in year flag (0=360,  1=366,  2=366J1, 3=actual)
 ${idm} 	  'idm   ' = longitudinal array size
 ${jdm}	  'jdm   ' = latitudinal  array size
   0	  'jdw   ' = width of zonal average
 ${idm_aux}	  'itest ' = grid point where detailed diagnostics are desired
 ${jdm_aux} 	  'jtest ' = grid point where detailed diagnostics are desired
  ${kdm}	  'kdm   ' = number of layers
  ${kdm}	  'nhybrd' = number of hybrid levels (0=all isopycnal)
      0	  'nsigma' = number of sigma  levels (nhybrd-nsigma z-levels)
   83.0	  'isotop' = shallowest depth for isopycnal layers (m), <0 from file
   1.00   'dp0k  ' = layer   1 deep    z-level spacing minimum thickness (m)
   1.80   'dp0k  ' = layer   2 deep    z-level spacing minimum thickness (m)
   3.24   'dp0k  ' = layer   3 deep    z-level spacing minimum thickness (m)
   4.68   'dp0k  ' = layer   4 deep    z-level spacing minimum thickness (m)
   4.93   'dp0k  ' = layer   5 deep    z-level spacing minimum thickness (m)
   5.81   'dp0k  ' = layer   6 deep    z-level spacing minimum thickness (m)
   6.87   'dp0k  ' = layer   7 deep    z-level spacing minimum thickness (m)
   8.00   'dp0k  ' = layer   8 deep    z-level spacing minimum thickness (m)
   8.00   'dp0k  ' = layer   9 deep    z-level spacing minimum thickness (m)
   8.00   'dp0k  ' = layer  10 deep    z-level spacing minimum thickness (m)
   8.00   'dp0k  ' = layer  11 deep    z-level spacing minimum thickness (m)
   8.00   'dp0k  ' = layer  12 deep    z-level spacing minimum thickness (m)
   8.00   'dp0k  ' = layer  13 deep    z-level spacing minimum thickness (m)
   8.00   'dp0k  ' = layer  14 deep    z-level spacing minimum thickness (m)
   8.00   'dp0k  ' = layer   A deep    z-level spacing minimum thickness (m)
   8.00   'dp0k  ' = layer   B deep    z-level spacing minimum thickness (m)
   8.00   'dp0k  ' = layer   C deep    z-level spacing minimum thickness (m)
   8.00   'dp0k  ' = layer   D deep    z-level spacing minimum thickness (m)
   8.00   'dp0k  ' = layer   E deep    z-level spacing minimum thickness (m)
   8.00   'dp0k  ' = layer   F deep    z-level spacing minimum thickness (m)
   8.00   'dp0k  ' = layer   G deep    z-level spacing minimum thickness (m)
   8.00   'dp0k  ' = layer   H deep    z-level spacing minimum thickness (m)
   8.00   'dp0k  ' = layer   I deep    z-level spacing minimum thickness (m)
  10.00   'dp0k  ' = layer  15 deep    z-level spacing minimum thickness (m)
  16.40   'dp0k  ' = layer  16 deep    z-level spacing minimum thickness (m)
  35.92   'dp0k  ' = layer  17 deep    z-level spacing minimum thickness (m)
  42.38   'dp0k  ' = layer  18 deep    z-level spacing minimum thickness (m)
  50.02   'dp0k  ' = layer  19 deep    z-level spacing minimum thickness (m)
  59.02   'dp0k  ' = layer  20 deep    z-level spacing minimum thickness (m)
  69.64   'dp0k  ' = layer  21 deep    z-level spacing minimum thickness (m)
  82.18   'dp0k  ' = layer  22 deep    z-level spacing minimum thickness (m)
  96.97   'dp0k  ' = layer  23 deep    z-level spacing minimum thickness (m)
 114.43   'dp0k  ' = layer  24 deep    z-level spacing minimum thickness (m)
 135.02   'dp0k  ' = layer  25 deep    z-level spacing minimum thickness (m)
 159.33   'dp0k  ' = layer  26 deep    z-level spacing minimum thickness (m)
 188.01   'dp0k  ' = layer  27 deep    z-level spacing minimum thickness (m)
 221.84   'dp0k  ' = layer  28 deep    z-level spacing minimum thickness (m)
 261.78   'dp0k  ' = layer  29 deep    z-level spacing minimum thickness (m)
 400.00   'dp0k  ' = layer  30 deep    z-level spacing minimum thickness (m)
 600.00   'dp0k  ' = layer  31 deep    z-level spacing minimum thickness (m)
 600.00   'dp0k  ' = layer  32 deep    z-level spacing minimum thickness (m)
   1.0   'dp00i'  = deep iso-pycnal spacing minimum thickness (m)
   2	  'thflag' = reference pressure flag (0=Sigma-0, 2=Sigma-2, 4=Sigma-4)
  34.0	  'thbase' = reference density (sigma units)
   1	  'vsigma' = spacially varying isopycnal target densities (0=F,1=T)
  17.00   'sigma ' = layer  1 isopycnal target density (sigma units)
  18.00   'sigma ' = layer  2 isopycnal target density (sigma units)
  19.00   'sigma ' = layer  3 isopycnal target density (sigma units)
  20.00   'sigma ' = layer  4 isopycnal target density (sigma units)
  21.00   'sigma ' = layer  5 isopycnal target density (sigma units)
  22.00   'sigma ' = layer  6 isopycnal target density (sigma units)
  23.00   'sigma ' = layer  7 isopycnal target density (sigma units)
  24.00   'sigma ' = layer  8 isopycnal target density (sigma units)
  25.00   'sigma ' = layer  9 isopycnal target density (sigma units)
  26.00   'sigma ' = layer 10 isopycnal target density (sigma units)
  27.00   'sigma ' = layer 11 isopycnal target density (sigma units)
  28.00   'sigma ' = layer 12 isopycnal target density (sigma units)
  29.00   'sigma ' = layer 13 isopycnal target density (sigma units)
  29.90   'sigma ' = layer 14 isopycnal target density (sigma units)
  30.65   'sigma ' = layer  A isopycnal target density (sigma units)
  31.35   'sigma ' = layer  B isopycnal target density (sigma units)
  31.95   'sigma ' = layer  C isopycnal target density (sigma units)
  32.55   'sigma ' = layer  D isopycnal target density (sigma units)
  33.15   'sigma ' = layer  E isopycnal target density (sigma units)
  33.75   'sigma ' = layer  F isopycnal target density (sigma units)
  34.30   'sigma ' = layer  G isopycnal target density (sigma units)
  34.80   'sigma ' = layer  H isopycnal target density (sigma units)
  35.20   'sigma ' = layer  I isopycnal target density (sigma units)
  35.50   'sigma ' = layer 15 isopycnal target density (sigma units)
  35.80   'sigma ' = layer 16 isopycnal target density (sigma units)
  36.04   'sigma ' = layer 17 isopycnal target density (sigma units)
  36.20   'sigma ' = layer 18 isopycnal target density (sigma units)
  36.38   'sigma ' = layer 19 isopycnal target density (sigma units)
  36.52   'sigma ' = layer 20 isopycnal target density (sigma units)
  36.62   'sigma ' = layer 21 isopycnal target density (sigma units)
  36.70   'sigma ' = layer 22 isopycnal target density (sigma units)
  36.77   'sigma ' = layer 23 isopycnal target density (sigma units)
  36.83   'sigma ' = layer 24 isopycnal target density (sigma units)
  36.89   'sigma ' = layer 25 isopycnal target density (sigma units)
  36.97   'sigma ' = layer 26 isopycnal target density (sigma units)
  37.02   'sigma ' = layer 27 isopycnal target density (sigma units)
  37.06   'sigma ' = layer 28 isopycnal target density (sigma units)
  37.10   'sigma ' = layer 29 isopycnal target density (sigma units)
  37.17   'sigma ' = layer 30 isopycnal target density (sigma units)
  37.30   'sigma ' = layer 31 isopycnal target density (sigma units)
  37.42   'sigma ' = layer 32 isopycnal target density (sigma units)
  19.2	  'thkmin' = minimum mixed-layer thickness (m)
EOF
 # 27.94   'sigma ' = layer 22  density (sigma units)
for i in {1..12};do
	printf "%02d\n" $i | read mm

	sed -e "s/^[ 	0-9]*'month ' =/  ${mm}	  'month ' =/" blkdat.input > fort.99

	touch      fort.71 fort.71A fort.72 fort.72A fort.73A
	/bin/rm -f fort.71 fort.71A fort.72 fort.72A fort.73A

#	mv ${run_path}/clim/dens_sig${sigma}_m${mm}.b fort.71
#	mv ${run_path}/clim/dens_sig${sigma}_m${mm}.a fort.71A
#	mv ${run_path}/clim/temp_sig${sigver}_m${mm}.b fort.72
#	mv ${run_path}/clim/temp_sig${sigver}_m${mm}.a fort.72A
#	mv ${run_path}/clim/saln_sig${sigver}_m${mm}.b fort.73
#	mv ${run_path}/clim/saln_sig${sigver}_m${mm}.a fort.73A

	mv ${run_path}/clim/temp_sig6_m${mm}.b fort.72
	mv ${run_path}/clim/temp_sig6_m${mm}.a fort.72A
	mv ${run_path}/clim/saln_sig6_m${mm}.b fort.73
	mv ${run_path}/clim/saln_sig6_m${mm}.a fort.73A



	export FOR010A=fort.10A
	export FOR011A=fort.11A
	export FOR012A=fort.12A
	export FOR021A=fort.21A
	export FOR051A=fort.51A
	export FOR071A=fort.71A
	export FOR072A=fort.72A
	export FOR073A=fort.73A
	
	touch fort.10  fort.11  fort.12  fort.21
	touch fort.10A fort.11A fort.12A fort.21A
	
	/bin/rm -f fort.10  fort.11  fort.12  fort.21
	/bin/rm -f fort.10A fort.11A fort.12A fort.21A

	#${run_path}/clim/relaxv_sig${sigma}
	${run_path}/clim/relaxi
	
	mv fort.10  relax_tem_m${mm}.b
	mv fort.10A relax_tem_m${mm}.a
	mv fort.11  relax_sal_m${mm}.b
	mv fort.11A relax_sal_m${mm}.a
	mv fort.12  relax_int_m${mm}.b
	mv fort.12A relax_int_m${mm}.a

	echo ${mm} | awk '{printf("0000_%3.3d_00\n",30*($1-1)+16)}' | read daym
	mv fort.21  relax.${daym}.b
	mv fort.21A relax.${daym}.a

	\rm fort.7[12]
done

# Merging all month climatologies in one file

cp relax_int_m01.b relax.intf.b
cp relax_sal_m01.b relax.saln.b
cp relax_tem_m01.b relax.temp.b

cp relax_int_m01.a relax.intf.a
cp relax_sal_m01.a relax.saln.a
cp relax_tem_m01.a relax.temp.a

for i in {2..12};do
	printf "%02d\n" $i | read mm
	tail -n +6 relax_int_m${mm}.b >> relax.intf.b
	tail -n +6 relax_sal_m${mm}.b >> relax.saln.b
	tail -n +6 relax_tem_m${mm}.b >> relax.temp.b
	cat relax_int_m${mm}.a >> relax.intf.a
	cat relax_sal_m${mm}.a >> relax.saln.a
	cat relax_tem_m${mm}.a >> relax.temp.a

#	\rm relax_int_m${mm}.b relax_sal_m${mm}.b relax_tem_m${mm}.b
#	\rm relax_int_m${mm}.a relax_sal_m${mm}.a relax_tem_m${mm}.a
done

