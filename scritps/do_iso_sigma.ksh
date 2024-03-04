#! /bin/ksh

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

touch   iso_density fort.61 fort.61A regional.grid.a regional.grid.b
/bin/rm iso_density fort.61 fort.61A regional.grid.a regional.grid.b

ln -sf ${hycom_root_dir}/${domain_name}/topo/regional.grid.a ${run_path}/clim
ln -sf ${hycom_root_dir}/${domain_name}/topo/regional.grid.b ${run_path}/clim
ln -sf ${hycom_root_dir}/${domain_name}/topo/regional.depth.a ${run_path}/clim/fort.61A
ln -sf ${hycom_root_dir}/${domain_name}/topo/regional.depth.b ${run_path}/clim/fort.61
ln -sf ${all_path}/relax/src/iso_density ${run_path}/clim


cat regional.grid.b | grep idm | cut -c3-9 | read idm
cat regional.grid.b | grep jdm | cut -c3-9 | read jdm

cd ${run_path}/clim

export FOR010A=fort.10A
export FOR061A=fort.61A

cat <<EOF > fort.99
 ${idm}	  'idm   ' = longitudinal array size
 ${jdm}	  'jdm   ' = latitudinal  array size
  41	  'kdm   ' = number of layers
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
  390      'if    ' = first i point of sub-region (<=0 to end)
  400      'il    ' = last  i point of sub-region
  230      'jf    ' = first j point of sub-region
  247      'jl    ' = last  j point of sub-region
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
  35.50   'sigma ' = layer  I isopycnal target density (sigma units)
  35.85   'sigma ' = layer 15 isopycnal target density (sigma units)
  36.20   'sigma ' = layer 16 isopycnal target density (sigma units)
  36.55   'sigma ' = layer 17 isopycnal target density (sigma units)
  36.90   'sigma ' = layer 18 isopycnal target density (sigma units)
  37.25   'sigma ' = layer 19 isopycnal target density (sigma units)
  37.50   'sigma ' = layer 20 isopycnal target density (sigma units)
  37.63   'sigma ' = layer 21 isopycnal target density (sigma units)
  37.69   'sigma ' = layer 22 isopycnal target density (sigma units)
  37.73   'sigma ' = layer 23 isopycnal target density (sigma units)
  37.76   'sigma ' = layer 24 isopycnal target density (sigma units)
  37.79   'sigma ' = layer 25 isopycnal target density (sigma units)
  37.82   'sigma ' = layer 26 isopycnal target density (sigma units)
  37.85   'sigma ' = layer 27 isopycnal target density (sigma units)
  37.88   'sigma ' = layer 28 isopycnal target density (sigma units)
  37.91   'sigma ' = layer 29 isopycnal target density (sigma units)
  37.94   'sigma ' = layer 30 isopycnal target density (sigma units)
  37.97   'sigma ' = layer 31 isopycnal target density (sigma units)
  401      'if    ' = first i point of sub-region (<=0 to end)
  451      'il    ' = last  i point of sub-region
  223      'jf    ' = first j point of sub-region
  254      'jl    ' = last  j point of sub-region
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
  35.50   'sigma ' = layer  I isopycnal target density (sigma units)
  35.85   'sigma ' = layer 15 isopycnal target density (sigma units)
  36.20   'sigma ' = layer 16 isopycnal target density (sigma units)
  36.55   'sigma ' = layer 17 isopycnal target density (sigma units)
  36.90   'sigma ' = layer 18 isopycnal target density (sigma units)
  37.25   'sigma ' = layer 19 isopycnal target density (sigma units)
  37.50   'sigma ' = layer 20 isopycnal target density (sigma units)
  37.63   'sigma ' = layer 21 isopycnal target density (sigma units)
  37.69   'sigma ' = layer 22 isopycnal target density (sigma units)
  37.73   'sigma ' = layer 23 isopycnal target density (sigma units)
  37.76   'sigma ' = layer 24 isopycnal target density (sigma units)
  37.79   'sigma ' = layer 25 isopycnal target density (sigma units)
  37.82   'sigma ' = layer 26 isopycnal target density (sigma units)
  37.85   'sigma ' = layer 27 isopycnal target density (sigma units)
  37.88   'sigma ' = layer 28 isopycnal target density (sigma units)
  37.91   'sigma ' = layer 29 isopycnal target density (sigma units)
  37.94   'sigma ' = layer 30 isopycnal target density (sigma units)
  37.97   'sigma ' = layer 31 isopycnal target density (sigma units)
   0	  'if    ' = first i point of sub-region (<=0 to end)
EOF



${run_path}/clim/iso_density


/bin/mv fort.10  iso_sigma.b
/bin/mv fort.10A iso_sigma.a

#/bin/rm -f  regional* core fort.* iso_density
