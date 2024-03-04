#! /bin/ksh
#
# This script downloads the atmospheric data from NCEP in hycom format
#
# Programmed by Leonardo Carvalho - LABESUL/UFES
#

idate=$1
fdate=$2


grep hycom_root_dir hycom_domain.input | cut -d":" -f2 | read hycom_root_dir
grep d01_lat hycom_domain.input	 | cut -d":" -f2 | read ilat
grep d01_lat hycom_domain.input	 | cut -d":" -f3 | read flat
grep d01_lon hycom_domain.input	 | cut -d":" -f2 | read ilon
grep d01_lon hycom_domain.input	 | cut -d":" -f3 | read flon

cfsr_data_path=${hycom_root_dir}/force/CFSR/data

if [[ ! -d ${cfsr_data_path} ]];then
	mkdir -p ${cfsr_data_path}
fi

cd ${cfsr_data_path}

#touch arch.dummy
#\rm *

echo $idate | cut -c1-4 | read iyyyy
echo $idate | cut -c5-6 | read imm
echo $idate | cut -c7-8 | read idd
echo $fdate | cut -c1-4 | read fyyyy
echo $fdate | cut -c5-6 | read fmm
echo $fdate | cut -c7-8 | read fdd

(( ilat -= 3 ))
(( flat += 3 ))
(( ilon -= 3 ))
(( flon += 3 ))

# If coordinates and time do not agree with hycom_domain.input, then get new atm data

if [[ -e ${cfsr_data_path}/atmospheric.log ]];then
	cat atmospheric.log | grep start_date | cut -d":" -f2 | read start_date
	cat atmospheric.log | grep end_date   | cut -d":" -f2 | read end_date
	cat atmospheric.log | grep lat        | cut -d":" -f2 | read ilat_aux
	cat atmospheric.log | grep lat        | cut -d":" -f3 | read flat_aux
	cat atmospheric.log | grep lon        | cut -d":" -f2 | read ilon_aux
	cat atmospheric.log | grep lon        | cut -d":" -f3 | read flon_aux

	if [[ $start_date > $idate || $end_date < $fdate ]];then
		aux=-1
	else
		aux=1
	fi

	if [[ 1 -eq "$(echo "${ilat_aux} < ${ilat}" | bc)" || 1 -eq "$(echo "${flat_aux} > ${flat}" | bc)" ]];then
		aux=-1
	else
		aux=1
	fi
	if [[ 1 -eq "$(echo "${ilon_aux} < ${ilon}" | bc)" || 1 -eq "$(echo "${flon_aux} > ${flon}" | bc)" ]];then
		aux=-1
	else
		aux=1
	fi
else
	aux=-1
fi

# Log this process, will useful later
echo "Atmospheric data download log, do not delete this file"  > ${cfsr_data_path}/atmospheric.log
echo " "  >> ${cfsr_data_path}/atmospheric.log
echo start_date	: $idate >> ${cfsr_data_path}/atmospheric.log
echo end_date	: $fdate >> ${cfsr_data_path}/atmospheric.log
echo lat	: $ilat : $flat >> ${cfsr_data_path}/atmospheric.log
echo lon	: $ilon : $flon >> ${cfsr_data_path}/atmospheric.log


if [[ $uax < 0 ]];then

	file1=cfsr-sea_01hr_TaqaQrQp.nc
	file2=cfsr-sea_01hr_precip.nc
	file3=cfsr-sea_01hr_surtmp.nc
	file4=cfsr-sec2_01hr_strblk.nc
	file5=cfsr-sec2_01hr_wndspd.nc



	wget -O $file5 "http://ncss.hycom.org/thredds/ncss/grid/datasets/force/ncep_cfsr/netcdf/cfsr-sec2_${fyyyy}_01hr_wndspd.nc?var=wndspd&north=${flat}&west=${ilon}&east=${flon}&south=${ilat}&horizStride=1&time_start=${iyyyy}-${imm}-${idd}T00%3A00%3A00Z&time_end=${fyyyy}-${fmm}-${fdd}T00%3A00%3A00Z&timeStride=1&addLatLon=true&accept=netcdf"

	wget -O $file4 "http://ncss.hycom.org/thredds/ncss/grid/datasets/force/ncep_cfsr/netcdf/cfsr-sec2_${fyyyy}_01hr_strblk.nc?var=tauewd&var=taunwd&north=${flat}&west=${ilon}&east=${flon}&south=${ilat}&horizStride=1&time_start=${iyyyy}-${imm}-${idd}T00%3A00%3A00Z&time_end=${fyyyy}-${fmm}-${fdd}T00%3A00%3A00Z&timeStride=1&addLatLon=true&accept=netcdf"

	wget -O $file3 "http://ncss.hycom.org/thredds/ncss/grid/datasets/force/ncep_cfsr/netcdf/cfsr-sea_${fyyyy}_01hr_surtmp.nc?var=surtmp&north=${flat}&west=${ilon}&east=${flon}&south=${ilat}&horizStride=1&time_start=${iyyyy}-${imm}-${idd}T00%3A00%3A00Z&time_end=${fyyyy}-${fmm}-${fdd}T00%3A00%3A00Z&timeStride=1&addLatLon=true&accept=netcdf"


	wget -O $file2 "http://ncss.hycom.org/thredds/ncss/grid/datasets/force/ncep_cfsr/netcdf/cfsr-sea_${fyyyy}_01hr_precip.nc?var=precip&north=${flat}&west=${ilon}&east=${flon}&south=${ilat}&horizStride=1&time_start=${iyyyy}-${imm}-${idd}T00%3A00%3A00Z&time_end=${fyyyy}-${fmm}-${fdd}T00%3A00%3A00Z&timeStride=1&addLatLon=true&accept=netcdf"
	
	wget -O $file1 "http://ncss.hycom.org/thredds/ncss/grid/datasets/force/ncep_cfsr/netcdf/cfsr-sea_${fyyyy}_01hr_TaqaQrQp.nc?var=airtmp&var=radflx&var=shwflx&var=vapmix&north=${flat}&west=${ilon}&east=${flon}&south=${ilat}&horizStride=1&time_start=${iyyyy}-${imm}-${idd}T00%3A00%3A00Z&time_end=${fyyyy}-${fmm}-${fdd}T00%3A00%3A00Z&timeStride=1&addLatLon=true&accept=netcdf"

else

	echo "Atmospheric data is compatible with grid and time..."
	echo "Skipping..."
fi
