#! /bin/ksh
#
# This script interpolates the atmospheric data from CFSR or era 15 climatology to the
# hycom grid.
#
# Usage: ./do_atm_forcing.ksh $grid_id $run_type $idate $fdate
# Where grid_id=domain id (1 father, 2 first nested...), run_type=hycom running type (clim for climatology
# or actual for actual days), idate and fdate the initial and final date, respctively in the format (yyyymmdd)
# for climatology idate and fdate do not change any model input. 
#
# Written by Leonardo Carvalho
#

# input from user
grid_id=$1
run_type=$2
idate=$3
fdate=$4

# grep from hycom_domain.input file

grep all_path hycom_domain.input		    | cut -d":" -f2	| read all_path
grep hycom_root_dir hycom_domain.input		| cut -d":" -f2	| read hycom_root_dir
grep d0${grid_id}_name hycom_domain.input	| cut -d":" -f2 | read domain_name

run_path=${hycom_root_dir}/${domain_name}/run

# Now I'll make the initial and final dates in the hycom's format (days from 1900/12/31)
# This is not used when clim option is on, but I'm keeping it because the processing time
# to this variables is less then 1/3 sec.

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



# SECTION FLUX - here I'm interpolating the fluxes to hycom's grid

if [[ ! -d ${run_path}/flux ]];then
	mkdir -p ${run_path}/flux
fi

cd ${run_path}/flux

touch arch.dummy
\rm *

ln -sf ${hycom_root_dir}/${domain_name}/topo/regional.grid.a ${run_path}/flux
ln -sf ${hycom_root_dir}/${domain_name}/topo/regional.grid.b ${run_path}/flux

case ${run_type} in	clim)
	export CDF071=era15-sea_1979-1993_mon_TaqaQrQp.D
	touch	fort.71
	\rm	fort.71
	ap=ap
	iffile=3
	ctitle="'TaqaQrQp era15 flux, monthly, MKS'"
	ln -sf ${hycom_root_dir}/data/force/era15/${CDF071} ${run_path}/flux/fort.71
	touch $CDF071
;;
        		actual)
	export CDF071=cfsr-sea_01hr_TaqaQrQp.nc
	export CDF072=cfsr-sea_01hr_TaqaQrQp.nc
	ap=ap_nc
	iffile=5
	ctitle="'CFSR-sea flux, 1hrly, MKS'"
	ln -sf ${hycom_root_dir}/data/force/CFSR/${CDF071} ${run_path}/flux
;;
esac

ln -sf ${all_path}/force/src/${ap} ${run_path}/flux

cat<<EOF> fort.temp
 &AFTITL
  CTITLE = '1234567890123456789012345678901234567890',
  CTITLE = ${ctitle},
 /
 &AFTIME
  HMKS   =   1.0,          !kg/kg             to kg/kg
  RMKS   =   1.0,          !W/m**2 into ocean to W/m**2 into ocean
  PMKS   =   1.1574074E-5, !m/day  into ocean to m/s    into ocean
  BIASPC =   0.0,
  PCMEAN =   0.0,
  BIASRD =   0.0,
  RDMEAN =   0.0,
  FSTART = ${t_start},
  TSTART = ${t_start},
  TMAX   = ${t_max},
 /
 &AFFLAG
  IFFILE =   ${iffile},  !3:monthly-climo; 5:actual-day;
  IFTYPE =   4,  !5:Ta-Ha-Qr-Qp-Pc; 4:Ta-Ha-Qr-Qp; 2:Qr; 1:Pc;
  INTERP =   0,  !0:piecewise-linear; 1:cubic-spline;
  INTMSK =   0,  !0:no mask; 1:land/sea=0/1; 2:land/sea=1/0;
 /
EOF

touch fort.10 fort.10a
\rm fort.1[0-4] fort.1[0-4]a

export FOR010A=fort.10a
export FOR011A=fort.11a
export FOR012A=fort.12a
export FOR013A=fort.13a
export FOR014A=fort.14a

${run_path}/flux/${ap} < fort.temp

/bin/mv fort.10  forcing.airtmp.b
/bin/mv fort.10a forcing.airtmp.a
/bin/mv fort.11  forcing.vapmix.b
/bin/mv fort.11a forcing.vapmix.a
/bin/mv fort.12  forcing.radflx.b
/bin/mv fort.12a forcing.radflx.a
/bin/mv fort.13  forcing.shwflx.b
/bin/mv fort.13a forcing.shwflx.a

\rm fort* ${ap} $CDF071
unset FOR010A FOR011A FOR012A FOR013A FOR014A CDF071 CDF072


# Preciptation

case ${run_type} in	clim)
	export CDF071=era15-sea_1979-1993_mon_ttlpcp.D
	touch	fort.71
	\rm	fort.71
	ap=kp
	ctitle="'era15 preciptation, monthly, MKS'"
	ln -sf ${hycom_root_dir}/data/force/era15/${CDF071} ${run_path}/flux/fort.71
	touch $CDF071
	
	cat<<EOF> fort.temp
 &AFTITL
  CTITLE = '1234567890123456789012345678901234567890',
  CTITLE = ${ctitle},
  CNAME  = 'precip',
 &END
 &AFTIME
  PARMIN =    0.0,  !precip is positive into ocean
  PARMAX =   99.0,  !disable maximum
  PAROFF =    0.0,  !disable offset
  PARSCL =    1.0,  !disable scale factor, already m/s into ocean (ERA40)
  PARSCL =    1.1574074E-5,   !m/day into ocean to m/s into ocean (ERA15)
 &END
 &AFFLAG
  INTERP =   0,  !0:piecewise-linear; 1:cubic-spline;
  INTMSK =   0,  !0:no mask; 1:land/sea=0/1; 2:land/sea=1/0;
 &END
EOF
;;
        		actual)
	export CDF071=cfsr-sea_01hr_precip.nc
	export CDF072=cfsr-sea_01hr_precip.nc
	ap=ap_nc
	iffile=5
	ctitle="'CFSR-sea preciptation, 1hrly, MKS'"
	ln -sf ${hycom_root_dir}/data/force/CFSR/${CDF071} ${run_path}/flux
	
	cat<<EOF> fort.temp
 &AFTITL
  CTITLE = '1234567890123456789012345678901234567890',
  CTITLE = ${ctitle},
 /
 &AFTIME
  HMKS   =   1.0,          !kg/kg             to kg/kg
  RMKS   =   1.0,          !W/m**2 into ocean to W/m**2 into ocean
  PMKS   =   0.001,        !m/s    into ocean
  BIASPC =   0.0,
  BIASRD =   0.0,
  FSTART = ${t_start},
  TSTART = ${t_start},
  TMAX   = ${t_max},
 /
 &AFFLAG
  IFFILE =   ${iffile},  !3:monthly-climo; 5:actual-day;
  IFTYPE =   1,  !5:Ta-Ha-Qr-Qp-Pc; 4:Ta-Ha-Qr-Qp; 2:Qr; 1:Pc;
  INTERP =   0,  !0:piecewise-linear; 1:cubic-spline;
  INTMSK =   0,  !0:no mask; 1:land/sea=0/1; 2:land/sea=1/0;
 /
EOF
;;
esac

ln -sf ${all_path}/force/src/${ap} ${run_path}/flux

touch fort.10 fort.10a
\rm fort.1[0-4] fort.1[0-4]a

export FOR010A=fort.10a
export FOR011A=fort.11a
export FOR012A=fort.12a
export FOR013A=fort.13a
export FOR014A=fort.14a

${run_path}/flux/${ap} < fort.temp

mv fort.10  forcing.precip.b
mv fort.10a forcing.precip.a

\rm fort* regional* ${ap} $CDF071

# Flux task done

# SECTION WIND - wind stresses and speed to hycom grid interpolation

if [[ ! -d ${run_path}/wind ]];then
	mkdir -p ${run_path}/wind
fi

cd ${run_path}/wind

touch arch.dummy
\rm *

ln -sf ${hycom_root_dir}/${domain_name}/topo/regional.grid.a ${run_path}/wind
ln -sf ${hycom_root_dir}/${domain_name}/topo/regional.grid.b ${run_path}/wind

case ${run_type} in	clim)
	export CDF071=era15-sea_1979-1993_mon_wndspd.D
	touch	fort.71
	\rm	fort.71
	kp=kp
	iffile=3
	ctitle="'era15 wind speed, monthly, MKS'"
	ln -sf ${hycom_root_dir}/data/force/era15/${CDF071} ${run_path}/wind/fort.71
	touch $CDF071
;;
        		actual)
	export CDF071=cfsr-sec2_01hr_wndspd.nc
	export CDF072=cfsr-sec2_01hr_wndspd.nc
	kp=kp_nc
	iffile=5
	ctitle="'CFSR-sec2 wind speed, 1hrly, MKS'"
	ln -sf ${hycom_root_dir}/data/force/CFSR/${CDF071} ${run_path}/wind
;;
esac

ln -sf ${all_path}/force/src/${kp} ${run_path}/wind

cat<<EOF> fort.temp
 &AFTITL
  CTITLE = '1234567890123456789012345678901234567890',
  CTITLE = ${ctitle},
  CNAME  = 'wndspd',
 &END
 &AFTIME
  FSTART = ${t_start},
  TSTART = ${t_start},
  TMAX   = ${t_max},
  PARMIN = -999.0,  !disable parmin
  PARMAX =  999.0,  !disable parmax
 &END
 &AFFLAG
  IFFILE =   ${iffile},  !3:monthly; 5:actual day;
  INTERP =   0,  !0:piecewise-linear; 1:cubic-spline;
  INTMSK =   0,  !0:no mask; 1:land/sea=0/1; 2:land/sea=1/0;
 &END
EOF

# Run wind speed interpolation
touch fort.10 fort.10a
\rm   fort.10 fort.10a

export FOR010A=fort.10a

${run_path}/wind/${kp} < fort.temp

mv fort.10  forcing.wndspd.b
mv fort.10a forcing.wndspd.a

\rm fort* ${kp} $CDF071
unset FOR010A

# Creating tau offset
ln -sf ${all_path}/force/src/off_zero ${run_path}/wind

export FOR010A=fort.10a
export FOR011A=fort.11a

${run_path}/wind/off_zero

mv fort.10  fort.44
mv fort.10a fort.44a
mv fort.11 fort.45
mv fort.11a fort.45a

unset FOR010A FOR011A
\rm off_zero

case ${run_type} in	clim)
	export CDF071=era15-sea_1979-1993_mon_strblk.D
	touch	fort.71
	\rm	fort.71
	wi=wi
	iwfile=1
	ctitle="'era15 wind stress, monthly, MKS'"
	ln -sf ${hycom_root_dir}/data/force/era15/${CDF071} ${run_path}/wind/fort.71
	touch $CDF071
;;
        		actual)
	export CDF071=cfsr-sec2_01hr_strblk.nc
	export CDF072=cfsr-sec2_01hr_strblk.nc
	wi=wi_nc
	iwfile=4
	ctitle="'CFSR-sec2 wind stress, 1hrly, MKS'"
	ln -sf ${hycom_root_dir}/data/force/CFSR/${CDF071} ${run_path}/wind
;;
esac

ln -sf ${all_path}/force/src/${wi} ${run_path}/wind

cat<<EOF> fort.temp
&WWTITL
  CTITLE = '123456789012345678901234567890123456789012345678901234567890',
  CTITLE = ${ctitle},
 /
 &WWTIME
  SPDMIN =   0.0,  !minimum allowed wind speed
  WSCALE =   1.0,  !scale factor to mks
  WSTART = ${t_start},
  TSTART = ${t_start},
  TMAX   = ${t_max},
 /
 &WWFLAG
  IGRID  = 2,  !0=p; 1=u&v; 2=p
  ISPEED = 0,  !0:none; 1:const; 2:kara; 3:coare
  INTERP = 3,  !0:bilinear; 1:cubic spline; 2:piecewise bessel; 3:piecewise bi-cubic
  INTMSK = 0,  !0:no mask; 1:land/sea=0/1; 2:l/s=1/0;
  IFILL  = 3,  !0,1:tx&ty; 2,3:magnitude; 1,3:smooth; (intmsk>0 only)
  IOFILE = 0,  !0:single offset; 1:multiple offsets; 2:multi-off no .b check
  IWFILE = ${iwfile},  !1:ann/mon; 2:multi-file; 4:actual wind day
 /
EOF

touch fort.10 fort.10a
\rm  fort.1[012] fort.1[012]a

export FOR010A=fort.10a
export FOR011A=fort.11a
export FOR012A=fort.12a
export FOR044A=fort.44a
export FOR045A=fort.45a

${run_path}/wind/${wi} < fort.temp

mv fort.10  forcing.tauewd.b
mv fort.10a forcing.tauewd.a
mv fort.11  forcing.taunwd.b
mv fort.11a forcing.taunwd.a

\rm fort* ${wi} ${CDF071}

# Now wind parameters just for climatology
case ${run_type} in	clim)
	# Wind curl
	
	cp  forcing.tauewd.b fort.10
	cp  forcing.tauewd.a fort.10a
	cp  forcing.taunwd.b fort.11
	cp  forcing.taunwd.a fort.11a

	ln -sf ${all_path}/force/src/wi_curl ${run_path}/wind

	export FOR010A=fort.10a
	export FOR011A=fort.11a
	export FOR012A=fort.12a
	
	${run_path}/wind/wi_curl

	mv fort.12  forcing.wndcrl.b
	mv fort.12a forcing.wndcrl.a

	\rm fort* wi_curl

	unset FOR010A FOR011A FOR012A

	# u-star
	ln -sf ${all_path}/force/src/kp ${run_path}/wind
	ln -sf ${hycom_root_dir}/data/force/era15/era15-sea_1979-1993_mon_u-star.D ${run_path}/wind/fort.71

	cat<<EOF> fort.temp
 &AFTITL
  CTITLE = '1234567890123456789012345678901234567890',
  CTITLE = "era15 u-star",
  CNAME  = 'u-star',
 &END
 &AFTIME
  PARMIN =  -99.0,  !disable minimum
  PARMAX =   99.0,  !disable maximum
  PAROFF =    0.0,  !disable offset
  TMPICE =   -1.7,  !ECMWF sea ice marker
 &END
 &AFFLAG
  INTERP =   0,  !0:piecewise-linear; 1:cubic-spline;
  INTMSK =   0,  !0:no mask; 1:land/sea=0/1; 2:land/sea=1/0;
 &END
EOF
	export FOR010A=fort.10A

	${run_path}/wind/kp < fort.temp

	mv fort.10  forcing.ustar.b
	mv fort.10A forcing.ustar.a

	\rm fort* kp
	
;;
esac

\rm regional*
# task finished in wind folder

# SECTION SURTMP - sea surface temperature

if [[ ! -d ${run_path}/surtmp ]];then
	mkdir -p ${run_path}/surtmp
fi

cd ${run_path}/surtmp

touch arch.dummy
\rm *

ln -sf ${hycom_root_dir}/${domain_name}/topo/regional.grid.a ${run_path}/surtmp
ln -sf ${hycom_root_dir}/${domain_name}/topo/regional.grid.b ${run_path}/surtmp

case ${run_type} in	clim)
	export CDF071=era15-sea_1979-1993_mon_soiltm.D
	touch	fort.71
	\rm	fort.71
	kp=kp
	iffile=3
	ctitle="'era15 surtmp, monthly, MKS'"
	ln -sf ${hycom_root_dir}/data/force/era15/${CDF071} ${run_path}/surtmp/fort.71
	touch $CDF071
;;
        		actual)
	export CDF071=cfsr-sea_01hr_surtmp.nc
	export CDF072=cfsr-sea_01hr_surtmp.nc
	kp=kp_nc
	iffile=4
	ctitle="'CFSR-sea surtmp, 1hrly, MKS'"
	ln -sf ${hycom_root_dir}/data/force/CFSR/${CDF071} ${run_path}/surtmp
;;
esac

ln -sf ${all_path}/force/src/${kp} ${run_path}/surtmp

cat<<EOF> fort.temp
 &AFTITL
  CTITLE = '1234567890123456789012345678901234567890',
  CTITLE = ${ctitle},
  CNAME  = 'surtmp',
 &END
 &AFTIME
  FSTART = ${t_start},
  TSTART = ${t_start},
  TMAX   = ${t_max},
  PARMIN = -999.0,  !disable parmin
  PARMAX =  999.0,  !disable parmax
  PAROFF = -273.16, !K to degC
  TMPICE =   -1.79, !sea ice marker
 &END
 &AFFLAG
  IFFILE =   ${iffile},  !3:monthly; 5:actual day;
  INTERP =   0,  !0:piecewise-linear; 1:cubic-spline;
  INTMSK =   0,  !0:no mask; 1:land/sea=0/1; 2:land/sea=1/0;
 &END
EOF

touch fort.10 fort.10a
\rm   fort.10 fort.10a

export FOR010A=fort.10a

${run_path}/surtmp/${kp} < fort.temp

mv fort.10  forcing.surtmp.b
mv fort.10a forcing.surtmp.a

sed -e "s/surtmp/seatmp/g"  forcing.surtmp.b > forcing.seatmp.b
cp forcing.surtmp.a forcing.seatmp.a

\rm fort* regional* ${kp} $CDF071

# end of surtmp task
# end of program
