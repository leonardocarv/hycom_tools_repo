#! /bin/ksh
#
# Description not given
#
grid_id=$1
kdm=$2
yrflag=$3
sigma=$4
nest_flag=$5

if [[ $yrflag = 0 ]];then
	dt_out=10
else
	dt_out=1
fi

grep hycom_root_dir hycom_domain.input	| cut -d":" -f2	| read hycom_root_dir
grep d0${grid_id}_name hycom_domain.input	| cut -d":" -f2 | read domain_name

topo_path=${hycom_root_dir}/${domain_name}/topo

cat ${topo_path}/regional.grid.b | grep idm | cut -c3-9 | read idm
cat ${topo_path}/regional.grid.b | grep jdm | cut -c3-9 | read jdm

bnstfq=0
nestfq=0
lbflag=0


case $nest_flag in nest)
	bnstfq=1
	nestfq=1
	lbflag=2
;;
esac

cat<<EOF> blkdat.input
ERA-15 climo. forcing: precip_zero; SSS relax;
7T Sigma0; Levitus July init; KPP mixed layer; Jerlov IA;
 Z(22): dp00/f/x=3m/1.125/12m; ATLb2.00/src_2.2.18; flxflg=4;
12345678901234567890123456789012345678901234567890123456789012345678901234567890
  22	  'iversn' = hycom version number x10
 010	  'iexpt ' = experiment number x10
 ${idm} 	  'idm   ' = longitudinal array size
 ${jdm}	  'jdm   ' = latitudinal  array size
  38	  'itest ' = grid point where detailed diagnostics are desired
  17	  'jtest ' = grid point where detailed diagnostics are desired
  ${kdm}	  'kdm   ' = number of layers
  ${kdm}	  'nhybrd' = number of hybrid levels (0=all isopycnal)
   0	  'nsigma' = number of sigma  levels (nhybrd-nsigma z-levels)
   3.0	  'dp00  ' = deep    z-level spacing minimum thickness (m)
  12.0	  'dp00x ' = deep    z-level spacing maximum thickness (m)
   1.125   'dp00f ' = deep    z-level spacing stretching factor (1.0=const.space)
   3.0	  'ds00  ' = shallow z-level spacing minimum thickness (m)
  12.0	  'ds00x ' = shallow z-level spacing maximum thickness (m)
   1.125   'ds00f ' = shallow z-level spacing stretching factor (1.0=const.space)
   1.0	  'dp00i ' = deep iso-pycnal spacing minimum thickness (m)
   6.0    'isotop' = shallowest depth for isopycnal layers (m), <0 from file
  35.0	  'saln0 ' = initial salinity value (psu), only used for iniflg<2
   1	  'locsig' = locally-referenced pot. density for stability (0=F,1=T)
   0	  'kapref' = thermobaric ref. state (-1=input,0=none,1,2,3=constant)
 ${sigma}	  'thflag' = reference pressure flag (0=Sigma-0, 2=Sigma-2)
  25.0	  'thbase' = reference density (sigma units)
   0	  'vsigma' = spacially varying isopycnal target densities (0=F,1=T)
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
  27.94   'sigma ' = layer 22  density (sigma units)
   2	  'iniflg' = initial state flag (0=levl, 1=zonl, 2=clim)
   2	  'jerlv0' = initial jerlov water type (1 to 5; 0 to use KPAR)
   ${yrflag}	  'yrflag' = days in year flag (0=360,  1=366,  2=366J1, 3=actual)
   0	  'sshflg' = diagnostic SSH flag (0=SSH,1=SSH&stericSSH)
   $dt_out	  'dsurfq' = number of days between model diagnostics at the surface
   $dt_out	  'diagfq' = number of days between model diagnostics
   0.0	  'tilefq' = number of days between model diagnostics on selected tiles
   0.0	  'meanfq' = number of days between model diagnostics (time averaged)
9999.0	  'rstrfq' = number of days between model restart output
   $bnstfq	  'bnstfq' = number of days between baro nesting archive input
   $nestfq	  'nestfq' = number of days between 3-d  nesting archive input
   0.125  'cplifq' = number of days (or time steps) between sea ice coupling
  180     'baclin' = baroclinic time step (seconds), int. divisor of 86400
  15	  'batrop' = barotropic time step (seconds), int. div. of baclin/2
   0      'incflg' = incremental update flag (0=no, 1=yes, 2=full-velocity)
  12      'incstp' = no. timesteps for full update (1=direct insertion)
   1      'incupf' = number of days of incremental updating input
   0.125  'wbaro ' = barotropic time smoothing weight
   1      'btrlfr' = leapfrog barotropic time step (0=F,1=T)
   0      'btrmas' = barotropic is mass conserving (0=F,1=T)
   8.0	  'hybrlx' = HYBGEN: inverse relaxation coefficient (time steps)
   0.01	  'hybiso' = HYBGEN: Use PCM if layer is within hybiso of target density
   3	  'hybmap' = hybrid  remapper  flag (0=PCM, 1=PLM,  2=PPM, 3=WENO-like)
   0	  'hybflg' = hybrid generator  flag (0=T&S, 1=th&S, 2=th&T)
   0	  'advflg' = thermal advection flag (0=T&S, 1=th&S, 2=th&T)
   2	  'advtyp' = scalar  advection type (0=PCM,1=MPDATA,2=FCT2,4=FCT4)
   2	  'momtyp' = momentum advection type (2=2nd order, 4=4th order)
  -1.0	  'slip  ' = +1 for free-slip, -1 for non-slip boundary conditions
   0.1	  'visco2' = deformation-dependent Laplacian  viscosity factor
   0.0	  'visco4' = deformation-dependent biharmonic viscosity factor
   0.0	  'facdf4' =       speed-dependent biharmonic viscosity factor
   0.03   'veldf2' = diffusion velocity (m/s) for Laplacian  momentum dissip.
   0.01   'veldf4' = diffusion velocity (m/s) for biharmonic momentum dissip.
   0.0    'thkdf2' = diffusion velocity (m/s) for Laplacian  thickness diffus.
   0.01   'thkdf4' = diffusion velocity (m/s) for biharmonic thickness diffus.
   0.015  'temdf2' = diffusion velocity (m/s) for Laplacian  temp/saln diffus.
   1.0	  'temdfc' = temp diffusion conservation (0.0,1.0 all dens,temp resp.)
   0.0    'vertmx' = diffusion velocity (m/s) for momentum at MICOM M.L.base
   0.05	  'cbar  ' = rms flow speed     (m/s) for linear bottom friction
   2.2e-3 'cb    ' = coefficient of quadratic bottom friction
   0.0	  'drglim' = limiter for explicit friction (1.0 none, 0.0 implicit)
   0.0	  'drgscl' = scale factor for tidal drag   (0.0 for no tidal drag)
 500.0	  'thkdrg' = thickness of bottom boundary layer for tidal drag (m)
  10.0	  'thkbot' = thickness of bottom boundary layer (m)
   0.02	  'sigjmp' = minimum density jump across interfaces  (kg/m**3)
   0.3	  'tmljmp' = equivalent temperature jump across mixed-layer (degC)
  15.0	  'thkmls' = reference mixed-layer thickness for SSS relaxation (m)
   0.0	  'thkmlt' = reference mixed-layer thickness for SST relaxation (m)
   6.0    'thkriv' = nominal thickness of river inflow (m)
  20.0    'thkfrz' = maximum thickness of near-surface freezing zone (m)
   1	  'iceflg' = sea ice model flag (0=none,1=energy loan,2=coupled/esmf)
   0.0    'tfrz_0' = ENLN: ice melting point (degC) at S=0psu
  -0.054  'tfrz_s' = ENLN: gradient of ice melting point (degC/psu)
   0.0    'ticegr' = ENLN: temp. grad. inside ice (deg/m); =0 use surtmp
   0.5    'hicemn' = ENLN: minimum ice thickness (m)
  10.0    'hicemx' = ENLN: maximum ice thickness (m)
   0	  'ntracr' = number of tracers (0=none,negative to initialize)
   0	  'trcflg' = tracer flags      (one digit per tr, most sig. replicated)
  64      'tsofrq' = number of time steps between anti-drift offset calcs
   0.0    'tofset' = temperature anti-drift offset (degC/century)
   0.0    'sofset' = salnity     anti-drift offset  (psu/century)
   1	  'mlflag' = mixed layer flag  (0=none,1=KPP,2-3=KT,4=PWP,5=MY,6=GISS)
   1	  'pensol' = KT:      activate penetrating solar rad.   (0=F,1=T)
 999.0	  'dtrate' = KT:      maximum permitted m.l. detrainment rate  (m/day)
  19.2    'thkmin' = KT/PWP:  minimum mixed-layer thickness (m)
   1	  'dypflg' = KT/PWP:  diapycnal mixing flag (0=none, 1=KPP, 2=explicit)
  64	  'mixfrq' = KT/PWP:  number of time steps between diapycnal mix calcs
   1.e-7  'diapyc' = KT/PWP:  diapycnal diffusivity x buoyancy freq. (m**2/s**2)
   0.25	  'rigr  ' = PWP:     critical gradient richardson number
   0.65	  'ribc  ' = PWP:     critical bulk     richardson number
   0.7	  'rinfty' = KPP:     maximum  gradient richardson number (shear inst.)
   0.25	  'ricr  ' = KPP:     critical bulk     richardson number
   0.0	  'bldmin' = KPP:     minimum surface boundary layer thickness (m)
1200.0	  'bldmax' = K-PROF:  maximum surface boundary layer thickness (m)
   0.7	  'cekman' = KPP/KT:  scale factor for Ekman depth
   1.0	  'cmonob' = KPP:     scale factor for Monin-Obukov depth
   0      'bblkpp' = KPP:     activate bottom boundary layer    (0=F,1=T)
   1	  'shinst' = KPP:     activate shear instability mixing (0=F,1=T)
   1	  'dbdiff' = KPP:     activate double diffusion  mixing (0=F,1=T)
   1	  'nonloc' = KPP:     activate nonlocal b. layer mixing (0=F,1=T)
   0	  'latdiw' = K-PROF:  activate lat.dep. int.wave mixing (0=F,1=T)
   0	  'botdiw' = GISS:    activate bot.enhan.int.wav mixing (0=F,1=T)
   0	  'difout' = K-PROF:  output visc/diff coffs in archive (0=F,1=T)
   0	  'difsmo' = K-PROF:  number of layers with horiz smooth diff coeffs
  50.0e-4 'difm0 ' = KPP:     max viscosity   due to shear instability (m**2/s)
  50.0e-4 'difs0 ' = KPP:     max diffusivity due to shear instability (m**2/s)
   0.3e-4 'difmiw' = KPP:     background/internal wave viscosity       (m**2/s)
   0.1e-4 'difsiw' = KPP:     background/internal wave diffusivity     (m**2/s)
  10.0e-4 'dsfmax' = KPP:     salt fingering diffusivity factor        (m**2/s)
   1.9	  'rrho0 ' = KPP:     salt fingering rp=(alpha*delT)/(beta*delS)
  98.96	  'cs    ' = KPP:     value for nonlocal flux term
  10.0	  'cstar ' = KPP:     value for nonlocal flux term
   1.8	  'cv    ' = KPP:     buoyancy frequency ratio (0.0 to use a fn. of N)
   5.0	  'c11   ' = KPP:     value for turb velocity scale
   2	  'hblflg' = KPP:     b. layer interp. flag (0=const.,1=linear,2=quad.)
   2	  'niter ' = KPP:     iterations for semi-implicit soln. (2 recomended)
   0      'fltflg' = FLOATS: synthetic float flag (0=no; 1=yes)
   4      'nfladv' = FLOATS: advect every nfladv bacl. time steps (even, >=4)
   1      'nflsam' = FLOATS: output (0=every nfladv steps; >0=no. of days)
   0      'intpfl' = FLOATS: horiz. interp. (0=2nd order+n.n.; 1=n.n. only)
   0      'iturbv' = FLOATS: add horiz. turb. advection velocity (0=no; 1=yes)
   1      'ismpfl' = FLOATS: sample water properties at float (0=no; 1=yes)
4.63e-6   'tbvar ' = FLOATS: horizontal turb. vel. variance scale (m**2/s**2)
   0.4    'tdecri' = FLOATS: inverse decorrelation time scale (1/day)
   $lbflag      'lbflag' = lateral barotropic bndy flag (0=none, 1=port, 2=input)
   0      'tidflg' = TIDES: tidal forcing flag    (0=none,1=open-bdy,2=bdy&body)
00000001  'tidcon' = TIDES: 1 digit per (Q1K2P1N2O1K1S2M2), 0=off,1=on
   0.06	  'tidsal' = TIDES: scalar self attraction and loading factor
   1	  'tidgen' = TIDES: generic time (0=F,1=T)
   1.0    'tidrmp' = TIDES:            ramp time  (days)
   0.0    'tid_t0' = TIDES: origin for ramp time  (model day)
  12	  'clmflg' = climatology frequency flag   (6=bimonthly, 12=monthly)
   2	  'wndflg' = wind stress input flag (0=none,1=u/v-grid,2,3=p-grid)
   4      'ustflg' = ustar   forcing   flag        (3=input,1,2=wndspd,4=stress)
   4	  'flxflg' = thermal forcing   flag (0=none,3=net-flux,1,2,4=sst-based)
   4      'empflg' = E-P     forcing   flag (0=none,3=net_E-P, 1,2,4=sst-bas_E)
   0      'dswflg' = diurnal shortwave flag (0=none,1=daily to diurnal corr.)
   1	  'sssflg' = SSS relaxation flag (0=none,1=clim)
   2	  'lwflag' = longwave (SST) flag (0=none,1=clim,2=atmos)
   ${yrflag}	  'sstflg' = SST relaxation flag (0=none,1=clim,2=atmos,3=observed)
   0	  'icmflg' = ice mask       flag (0=none,1=clim,2=atmos,3=obs/coupled)
   0      'flxoff' = net flux offset flag   (0=F,1=T)
   0	  'flxsmo' = smooth surface fluxes  (0=F,1=T)
   1	  'relax ' = activate lateral boundary nudging    (0=F,1=T)
   0	  'trcrlx' = activate lat. bound. tracer nudging  (0=F,1=T)
   1	  'priver' = rivers as a precipitation bogas      (0=F,1=T)
   0      'epmass' = treat evap-precip as a mass exchange (0=F,1=T)
EOF

#  27.94   'sigma ' = layer 22  density (sigma units)
