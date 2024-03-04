#! /bin/ksh
#
# This script writes the river files to the hycom simulation
#
grid_id=$1

grep all_path hycom_domain.input		| cut -d":" -f2	| read all_path
grep scpt_dir hycom_domain.input		| cut -d":" -f2	| read scpt_dir
grep hycom_root_dir hycom_domain.input		| cut -d":" -f2	| read hycom_root_dir
grep d0${grid_id}_name hycom_domain.input	| cut -d":" -f2 | read domain_name
grep d0${grid_id}_lat hycom_domain.input	| cut -d":" -f2 | read ilat
grep d0${grid_id}_lat hycom_domain.input	| cut -d":" -f3 | read flat
grep d0${grid_id}_lon hycom_domain.input	| cut -d":" -f2 | read ilon
grep d0${grid_id}_lon hycom_domain.input	| cut -d":" -f3 | read flon

river_path=${hycom_root_dir}/${domain_name}/run/rivers
topo_path=${hycom_root_dir}/${domain_name}/topo

if [[ ! -d ${river_path} ]];then
	mkdir -p ${river_path}
fi

cd ${river_path}

# Find rivers in the desired region
${all_path}/bin/hycom_rivers ${ilon} ${flon} ${ilat} ${flat} > rivers_all.txt

# Find ij rivers location
grep "[A-Z]" rivers_all.txt | cut -c 33-55 > rivers_names.txt
grep "[A-Z]" rivers_all.txt | cut -c 11-30 > rivers_lonlat.txt
${all_path}/bin/hycom_lonlat2ij ${topo_path}/regional.grid.a < rivers_lonlat.txt > rivers_ij.txt
paste rivers_ij.txt rivers_lonlat.txt rivers_names.txt

# Extract rivers transport
grep -v '[A-Z]' rivers_all.txt | grep -v '^ *$' | cut -c 41- > rivers_tr.txt

# Make the river files to hycom

ln -sf ${topo_path}/regional.grid.a ${river_path}
ln -sf ${topo_path}/regional.grid.b ${river_path}
ln -sf ${topo_path}/regional.depth.a ${river_path}/fort.51A
ln -sf ${topo_path}/regional.depth.b ${river_path}/fort.51

ln -sf ${all_path}/force/src/pcip_riv_mon ${river_path}

export FOR014A=fort.14A
export FOR051A=fort.51A

wc -l ${river_path}/rivers_names.txt | cut -d" " -f1 | read nrivers

cat <<EOF> fort.temp
 &RTITLE
  CTITLE = '1234567890123456789012345678901234567890123456789012345678901234567890123456789',
  CTITLE = 'top 350 rivers from NRL database, except:',
           'Ob,Danube,Neva,Nile,Dnieper,Taz,Abitibi,Nottaway,Pur,Eastmain,Rupert,Don',
           'Nadym,Vuoksi,Narva,Harricana,Rioni,Neretva,Kuban,Dniestr,Drin,Tiber',
 /
 &RIVERS
  NRIVERS =  ${nrivers},
  NSMOOTH =    5,
  MAXDIST =   10,
  IGNORE  = .TRUE.,   !ignore river placement errors (default .false.)
  IJRIVER =  
EOF

cat ${river_path}/rivers_ij.txt >> fort.temp

cat <<EOF>> fort.temp
  TSCALE  = 1.E-6, !m^3/s to Sv
  TRIVER  = 
EOF

cat ${river_path}/rivers_tr.txt >> fort.temp
echo / >> fort.temp

${river_path}/pcip_riv_mon < fort.temp

mv ${river_path}/fort.14  ${river_path}/forcing.rivers.b
mv ${river_path}/fort.14A ${river_path}/forcing.rivers.a

\rm fort.51A fort.51 *.txt pcip_riv_mon fort.temp regional*
