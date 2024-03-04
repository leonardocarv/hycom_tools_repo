#! /bin/ksh
#
# This script makes the bathymetry and the needed input files to run a hycom nested
# application.
#
# Written by Leonardo Carvalho - LABESUL/UFES
#

grid_id=$1
idate=$2
fdate=$3

grep all_path hycom_domain.input		| cut -d":" -f2	| read all_path
grep scpt_dir hycom_domain.input		| cut -d":" -f2	| read scpt_dir
grep hycom_root_dir hycom_domain.input		| cut -d":" -f2	| read hycom_root_dir
grep d0${grid_id}_name hycom_domain.input	| cut -d":" -f2 | read domain_name

echo "scale=0; $grid_id - 1" | bc -l | read father_id

grep d0${father_id}_name hycom_domain.input	| cut -d":" -f2 | read father_domain_name


# Relation between the grids
grep d0${grid_id}_lon hycom_domain.input	 | cut -d":" -f2 | read ilon
grep d0${father_id}_lon hycom_domain.input	 | cut -d":" -f2 | read father_ilon
grep d0${father_id}_dx hycom_domain.input	 | cut -d":" -f2 | read father_dx
grep d0${father_id}_dy hycom_domain.input	 | cut -d":" -f2 | read father_dy
grep d0${grid_id}_dx hycom_domain.input		 | cut -d":" -f2 | read dx
grep d0${grid_id}_dy hycom_domain.input		 | cut -d":" -f2 | read dy

## System paths

nest_path=${hycom_root_dir}/${domain_name}
father_path=${hycom_root_dir}/${father_domain_name}
scratch_path=${nest_path}/run/scratch
restart_path=${nest_path}/run/restart

if [[ ! -d $scratch_path/nest ]];then
	mkdir -p $scratch_path/nest
fi

cd $scratch_path/nest

touch arch.dummy
\rm *

cat ${nest_path}/topo/regional.grid.b   | grep plat | cut -d"=" -f2 | cut -d" " -f8 | read ilat
cat ${father_path}/topo/regional.grid.b | grep plat | cut -d"=" -f2 | cut -d" " -f8 | read father_ilat
cat ${father_path}/topo/pntlat.log      | cut -d"=" -f2 | read pntlat

echo "scale=0; ($ilon - $father_ilon)/$father_dx" | bc -l | read irefi
echo "scale=0; $father_dx/$dx" | bc -l | read ijgrd

jrefi=0

# Test for jrefi (hard to know how grid size changes with latitude, but here it is)

while [ 1 -eq "$(echo "${ilat} >= ${father_ilat}" | bc)" ]; do
	(( jrefi += 1 ))
	echo "scale=7; (2*a(e(${father_dy}*(${jrefi}-${pntlat})/57.29578)) - 1.5707963268)*57.29578" | bc -l | read father_ilat

done

# Calculate the time by means of hycom reference (1900123100)
date --date="19001231 00:00:00" +%s	| read t
date --date="$idate 00:00:00" +%s 	| read i
date --date="$fdate 00:00:00" +%s	| read j

t_start=0
t_max=0
dt=86400
dt_input=1
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


while (( $t_max >= $t_start ));do

	ln -sf ${father_path}/topo/regional.grid.a $scratch_path/nest/regional.grid.a
	ln -sf ${father_path}/topo/regional.grid.b $scratch_path/nest/regional.grid.b

	cat ${nest_path}/topo/regional.grid.b | grep idm | cut -d" " -f3 | read idm
	cat ${nest_path}/topo/regional.grid.b | grep jdm | cut -d" " -f3 | read jdm

	echo 3 1 1 $t_start $t_start | $all_path/bin/hycom_nest_dates | read ydh

	cat <<EOF> fort.temp
$father_path/run/results/archv.${ydh}.b
$father_path/topo/regional.depth.b
$scratch_path/nest/archv.${ydh}_L22.b
$nest_path/topo/regional.depth.b
$father_domain_name interpolated to $domain_name
 $idm	  'idm   ' = longitudinal array size
 $jdm	  'jdm   ' = latitudinal  array size
  $irefi	  'irefi ' = longitudinal input  reference location
  $jrefi	  'jrefi ' = latitudinal  input  reference location
   1	  'irefo ' = longitudinal output reference location
   1	  'jrefo ' = latitudinal  output reference location
   $ijgrd	  'ijgrd ' = integer scale factor between input and output grids
   0	  'iceflg' = ice in output archive flag (0=none,1=energy loan model)
   1	  'smooth' = smooth interface depths    (0=F,1=T)
EOF

	$all_path/subregion/src/isubregion < fort.temp

	\rm regional* *.temp
	
	ln -sf ${nest_path}/topo/regional.grid.a $scratch_path/nest/regional.grid.a
	ln -sf ${nest_path}/topo/regional.grid.b $scratch_path/nest/regional.grid.b
	ln -sf ${nest_path}/topo/regional.depth.a $scratch_path/nest/regional.depth.a
	ln -sf ${nest_path}/topo/regional.depth.b $scratch_path/nest/regional.depth.b

	cat <<EOF> fort.temp
$nest_path/run/scratch/nest/archv.${ydh}_L22.b
$nest_path/run/scratch/nest/archv.${ydh}.b
000	'iexpt ' = experiment number x10 (000=from archive file)
  3	'yrflag' = days in year flag (0=360J16,1=366J16,2=366J01,3-actual)
$idm	'idm   ' = longitudinal array size
$jdm	'jdm   ' = latitudinal  array size
 22	'kdmold' = original number of layers
 21	'kdmnew' = target   number of layers
  25.0   'thbase' = reference density (sigma units)
  19.50   'sigma ' = layer  1  density (sigma units)
  20.25   'sigma ' = layer  2  density (sigma units)
  21.00   'sigma ' = layer  3  density (sigma units)
  21.75   'sigma ' = layer  4  density (sigma units)
  22.50   'sigma ' = layer  5  density (sigma units)
  23.25   'sigma ' = layer  6  density (sigma units)
  24.00   'sigma ' = layer  7  density (sigma units)
  24.70   'sigma ' = layer  8  density (sigma units)
  25.28   'sigma ' = layer  9  density (sigma units)
  25.77   'sigma ' = layer 10  density (sigma units)
  26.18   'sigma ' = layer 11  density (sigma units)
  26.52   'sigma ' = layer 12  density (sigma units)
  26.80   'sigma ' = layer 13  density (sigma units)
  27.03   'sigma ' = layer 14  density (sigma units)
  27.22   'sigma ' = layer 15  density (sigma units)
  27.38   'sigma ' = layer 16  density (sigma units)
  27.52   'sigma ' = layer 17  density (sigma units)
  27.64   'sigma ' = layer 18  density (sigma units)
  27.74   'sigma ' = layer 19  density (sigma units)
  27.82   'sigma ' = layer 20  density (sigma units)
  27.88   'sigma ' = layer 21  density (sigma units)
EOF

	$all_path/archive/src/trim_archv < fort.temp
#	\rm regional* *.temp archv.${ydh}_L22.b archv.${ydh}_L22.a
	(( t_start += $dt_input ))
done

# I'll make the ports.input here, it will be more easier

# Running matlab script to get the ports limits

cat <<EOF> port_limits.m
clear all
close all
clc

bat=read_depth_hycom($idm,$jdm,'${nest_path}/topo/regional.depth.a');

 bat_north = bat(end-1,:);
 bat_east = bat(:,end);
 
 fid = fopen('$scratch_path/nest/iport.dat','wt');
 
 % building the boundary segments
 for i = 2:length(bat_north)-1

     if (~isnan(bat_north(i)) && isnan(bat_north(i-1)))
         ifport = i;
         fprintf(fid,'%3g %s',ifport,' > ');
     end
     if (isnan(bat_north(i+1)) && ~isnan(bat_north(i))) || (i == length(bat_north) - 1)
         ilport = i;
         fprintf(fid,'%3g\n',ilport);
     end     
 end
fclose(fid);
EOF

matlab -nojvm -nodisplay -nosplash < port_limits.m

cat iport.dat | cut -d">" -f1 | read ifport
cat iport.dat | cut -d">" -f2 | read ilport

echo "scale=0; $jdm - 1" | bc -l | read jlport

cat <<EOF> ports.input
2       'nports' = number of boundary port sections
1       'kdport' = port orientation (1=N, 2=S, 3=E, 4=W)
$ifport     'ifport' = first i-index
$ilport     'ilport' = last i-index (=ifport for north/south port)
$jdm     'jfport' = first j-index
$jdm     'jlport' = last j-index (=jfport for east/west port)
3       'kdport' = port orientation (1=N, 2=S, 3=E, 4=W)
$idm     'ifport' = first i-index
$idm     'ilport' = last i-index (=ifport for north/south port
2       'jfport' = first j-index
$jlport     'jlport' = last j-index (=jfport for east/west port)
5.0   'pefold' = port transport e-folding time in days
EOF

\rm port_limits.m iport.dat 
