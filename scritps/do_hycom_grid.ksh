#! /bin/ksh

# This program creates the regional.[a,b] used to biuld the bathymetry
# This uses hycom_domain.input file (set it properly)
# 
# Programmed by Leonardo Carvalho

grid_id=$1

grep hycom_root_dir hycom_domain.input 		 | cut -d":" -f2 | read hycom_root_dir
grep all_path hycom_domain.input 		 | cut -d":" -f2 | read all_path 
grep d0${grid_id}_name hycom_domain.input	 | cut -d":" -f2 | read grid_id_name
grep d0${grid_id}_lat hycom_domain.input	 | cut -d":" -f2 | read ilat
grep d0${grid_id}_lat hycom_domain.input	 | cut -d":" -f3 | read flat
grep d0${grid_id}_lon hycom_domain.input	 | cut -d":" -f2 | read ilon
grep d0${grid_id}_lon hycom_domain.input	 | cut -d":" -f3 | read flon
grep d0${grid_id}_dx hycom_domain.input		 | cut -d":" -f2 | read dx
grep d0${grid_id}_dy hycom_domain.input		 | cut -d":" -f2 | read dy


if [[ ! -d ${hycom_root_dir}/${grid_id_name}/topo ]]; then
	mkdir -p ${hycom_root_dir}/${grid_id_name}/topo
fi

cd ${hycom_root_dir}/${grid_id_name}/topo

echo ${flon} ${ilon} ${ilat} ${flat} ${dx} ${dy}

echo "scale=0; (${flon} - ${ilon})/${dx}" | bc -l | read idm
echo "scale=0; (${flat} - ${ilat})/${dy}" | bc -l | read jdm

# Creating temporary regional.grid.b file

# Make trial and error test for the best pntlat to ajust the grid
# Not good (really bad), but works anyway
aux_diff=100000.0
pntlat=1
print ${ilat#-} | read ilat_abs
print ${flat#-} | read flat_abs

for i in {346..347};do

cat <<EOF> regional.grid.b
  ${idm}	'idm   ' = longitudinal array size
  ${jdm}	'jdm   ' = latitudinal  array size
EOF

export FOR061=fort.61
export FOR061A=fort.61A

	cat <<EOF> fort.temp
${idm} 	'idm   ' = longitudinal array size
${jdm}	'jdm   ' = latitudinal  array size
  0	'mapflg' = map flag (0=mercator,2=uniform,4=f-plane)
  1.0	'pntlon' = longitudinal reference grid point on pressure grid
${ilon}	'reflon' = longitude of reference grid point on pressure grid
  ${dx}	'grdlon' = longitudinal grid size (degrees)
 $i	'pntlat' = latitudinal  reference grid point on pressure grid
  0.0	'reflat' = latitude of  reference grid point on pressure grid
${dy}	'grdlat' = latitudinal  grid size at the equator (degrees)
EOF

	${all_path}/topo/src/grid_mercator < fort.temp

	mv fort.61  regional.grid.b
	mv fort.61A regional.grid.a

	cat regional.grid.b | sed -n 5p | cut -d"=" -f2 | cut -c1-20  | read ilat_aux
	print ${ilat_aux#-} | read ilat_aux
	cat regional.grid.b | sed -n 5p | cut -d"=" -f2 | cut -c22-33 | read flat_aux
	print ${flat_aux#-} | read flat_aux
	
	echo "scale=6; (${ilat_abs} - ${ilat_aux})"   | bc -l | read ilat_diff
	print ${ilat_diff#-} | read ilat_diff
	echo "scale=6; (${flat_abs} - ${flat_aux})"   | bc -l | read flat_diff
	print ${flat_diff#-} | read flat_diff
	echo "scale=6; (${ilat_diff} + ${flat_diff})" | bc -l | read diff


	if [ 1 -eq "$(echo "${diff} < ${aux_diff}" | bc)" ];then  
		aux_diff=${diff}
		pntlat=$i
		echo "Best pntlat = " $i > pntlat.log
	fi

	\rm *.temp *regional*
done

##### End Trial and Error

cat <<EOF> regional.grid.b
  ${idm}	'idm   ' = longitudinal array size
  ${jdm}	'jdm   ' = latitudinal  array size
EOF

export FOR061=fort.61
export FOR061A=fort.61A

cat <<EOF> fort.temp
${idm} 	'idm   ' = longitudinal array size
${jdm}	'jdm   ' = latitudinal  array size
  0	'mapflg' = map flag (0=mercator,2=uniform,4=f-plane)
  1.0	'pntlon' = longitudinal reference grid point on pressure grid
${ilon}	'reflon' = longitude of reference grid point on pressure grid
  ${dx}	'grdlon' = longitudinal grid size (degrees)
$pntlat	'pntlat' = latitudinal  reference grid point on pressure grid
  0.0	'reflat' = latitude of  reference grid point on pressure grid
${dy}	'grdlat' = latitudinal  grid size at the equator (degrees)
EOF

${all_path}/topo/src/grid_mercator < fort.temp

\rm fort.temp
mv fort.61  regional.grid.b
mv fort.61A regional.grid.a

# Interpolate the bathymetry from gebco 30 sec

export FOR061=fort.61
export FOR061A=fort.61A

touch $FOR061 $FOR061A
\rm $FOR061 $FOR061A

export CDF_GEBCO=${hycom_root_dir}/data/topo/gebco/GEBCO_2020.nc

ln -sf ${all_path}/topo/src/bathy_15sec ${hycom_root_dir}/${grid_id_name}/topo

cat <<EOF> fort.temp
 &TOPOG
  CTITLE = 'bathymetery from 30-second GEBCO_08 20091120 global dataset, new 11x11 average',
  COAST  =     0.1, ! DEPTH OF MODEL COASTLINE (-ve keeps orography)
  FLAND  =     0.0, ! FAVOR LAND VALUES
  INTERP = 1,       ! =-N; AVERAGE OVER (2*N+1)x(2*N+1) GRID PATCH
                    ! = 0; PIECEWISE LINEAR.  = 1; CUBIC SPLINE.
  MTYPE  =  0,      ! = 0; CLOSED DOMAIN. = 1; NEAR GLOBAL. = 2; FULLY GLOBAL.
 /
EOF

${hycom_root_dir}/${grid_id_name}/topo/bathy_15sec < fort.temp

mv fort.61  regional.depth.b
mv fort.61A regional.depth.a

\rm *.temp bathy_15sec


# Make partit file for mpi run

export FOR051=regional.depth.b
export FOR051A=regional.depth.a

m=6
n=8

echo "$n $m 0.75" | ${all_path}/topo/src/partit
mv fort.21 patch.input

# Clip the bathymetry to 10m and smooth it

export FOR051=fort.51
export FOR051A=fort.51A
export FOR061=fort.61
export FOR061A=fort.61A
#
/bin/ln -sf regional.depth.b fort.51
/bin/ln -sf regional.depth.a fort.51A


cat <<EOF> fort.temp
10.0 11000.0
EOF


${all_path}/topo/src/topo_clip < fort.temp

/bin/mv fort.61  regional.depth.b
/bin/mv fort.61A regional.depth.a

/bin/rm -f fort.*

/bin/ln -s regional.depth.b fort.51
/bin/ln -s regional.depth.a fort.51A

cat <<EOF> fort.temp
1 2
EOF


${all_path}/topo/src/topo_smooth_skip < fort.temp

/bin/mv fort.61  regional.depth.b
/bin/mv fort.61A regional.depth.a

/bin/rm -f fort*

