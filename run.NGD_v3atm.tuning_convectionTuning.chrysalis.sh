#!/bin/bash -fe

# E3SM Water Cycle v2 run_e3sm script template.
#
# Inspired by v1 run_e3sm script as well as SCREAM group simplified run script.
#
# Bash coding style inspired by:
# http://kfirlavi.herokuapp.com/blog/2012/11/14/defensive-bash-programming

main() {

# For debugging, uncomment libe below
#set -x

# --- Configuration flags ----

# Machine and project
readonly MACHINE=chrysalis
readonly PROJECT="e3sm"

# Simulation
readonly COMPSET="F20TR_chemUCI-Linozv3"
readonly RESOLUTION="ne30pg2_EC30to60E2r2"
readonly CASE_NAME="NGD_v3atm_ne30pg2_clubb_c50ab36"

# Code and compilation
readonly CHECKOUT="20221109"
readonly BRANCH="bmg929/atm/NGD_v3atm_clubb_c50ab36" # a848108516f1531f28acf09d915c4db765ac1102, tangq/atm/chemUCI_amip as of 20220518
readonly CHERRY=( )
readonly DEBUG_COMPILE=false

# Run options
readonly MODEL_START_TYPE="hybrid"  # 'initial', 'continue', 'branch', 'hybrid'
readonly START_DATE="2005-01-01"

# Additional options for 'branch' and 'hybrid'
readonly GET_REFCASE=TRUE
readonly RUN_REFDIR="/lcrc/group/e3sm/ac.mwu/archive/20221103.v2.LR.amip.NGD_v3atm.chrysalis/archive/rest/2005-01-01-00000"
readonly RUN_REFCASE="20221103.v2.LR.amip.NGD_v3atm.chrysalis"
readonly RUN_REFDATE="2005-01-01"

# Set paths
readonly CODE_ROOT="/home/ac.griffin/NGD_v3atm_clubb_c50ab36"
readonly CASE_ROOT="/lcrc/group/acme/ac.griffin/E3SM_simulations/${CASE_NAME}"
readonly MY_INPUT_DATA_PATH="/lcrc/group/e3sm/ac.mwu/inputdata"

# Sub-directories
readonly CASE_BUILD_DIR=${CASE_ROOT}/build
readonly CASE_ARCHIVE_DIR=${CASE_ROOT}/archive

# Define type of run
#  short tests: 'S_2x5_ndays', 'M_1x10_ndays', 'M80_1x10_ndays'
#  or 'production' for full simulation
readonly run='production'

#readonly run='custom-30_2x5_ndays'
#readonly run='custom-30_1x10_ndays'
#readonly run='custom-10_2x5_ndays'
#readonly run='custom-10_1x10_ndays'

if [ "${run}" != "production" ]; then

  # Short test simulations
  tmp=($(echo $run | tr "_" " "))
  layout=${tmp[0]}
  units=${tmp[2]}
  resubmit=$(( ${tmp[1]%%x*} -1 ))
  length=${tmp[1]##*x}

  readonly CASE_SCRIPTS_DIR=${CASE_ROOT}/tests/${run}/case_scripts
  readonly CASE_RUN_DIR=${CASE_ROOT}/tests/${run}/run
  #readonly PELAYOUT=${layout}
  readonly PELAYOUT="custom-30"
  readonly WALLTIME="2:00:00"
  readonly STOP_OPTION=${units}
  readonly STOP_N=${length}
  readonly REST_OPTION=${STOP_OPTION}
  readonly REST_N=${STOP_N}
  readonly RESUBMIT=${resubmit}
  readonly DO_SHORT_TERM_ARCHIVING=false

else

  # Production simulation
  readonly CASE_SCRIPTS_DIR=${CASE_ROOT}/case_scripts
  readonly CASE_RUN_DIR=${CASE_ROOT}/run
  #readonly PELAYOUT="M"
  readonly PELAYOUT="custom-30"
  readonly WALLTIME="28:00:00"
  readonly STOP_OPTION="nyears"
  readonly STOP_N="10"
  readonly REST_OPTION="nyears"
  readonly REST_N="5"
  readonly RESUBMIT="0"
  readonly DO_SHORT_TERM_ARCHIVING=false
fi

# Coupler history 
readonly HIST_OPTION="nyears"
readonly HIST_N="1"

# Leave empty (unless you understand what it does)
readonly OLD_EXECUTABLE=""

# --- Toggle flags for what to do ----
do_fetch_code=false
do_create_newcase=true
do_case_setup=true
do_case_build=true
do_case_submit=true

# --- Now, do the work ---

# Make directories created by this script world-readable
umask 022

# Fetch code from Github
fetch_code

# Create case
create_newcase

# Custom PE layout
custom_pelayout

# Setup
case_setup

# Build
case_build

# Configure runtime options
runtime_options

# Copy script into case_script directory for provenance
copy_script

# Submit
case_submit

# All done
echo $'\n----- All done -----\n'

}

# =======================
# Custom user_nl settings
# =======================

user_nl() {

cat << EOF >> user_nl_eam
 nhtfrq = 0,0,-1,-24,-6,-3,-1,-27
 mfilt  = 1,1,240,30,120,240,240,240
 avgflag_pertape = 'A','I','I','A','A','A','I','I'

 fincl1 = 'TVQ','TUQ','U200','U850','E90','N2OLNZ','NOYLNZ','H2OLNZ','CH4LNZ','MASS','AREA','TOZ',
          'TROPC_P','TROPC_T','TROPC_Z','TROPS_P','TROPS_T','TROPS_Z',
          'TROPT_P','TROPT_T','TROPT_Z','TROPW_P','TROPW_T','TROPW_Z',
          'TROPH_P','TROPH_T','TROPH_Z','TROPE_P','TROPE_T','TROPE_Z',
          'M_dens','H2O_vmr','CH4','NO_Lightning','NO_Aircraft','CO_Aircraft','CH4_vmr',
          'prsd_ch4','LNO_COL_PROD','LNO_PROD','DV_O3','PSDRY','lch4','r_lch4','lco_h','r_lco_h','uci1','r_uci1'
 fincl3 = 'O3_SRF'
 fincl4 = 'TCO','SCO','PRECC','PRECT','U200','V200','TMQ','FLUT','U850','V850','OMEGA500'
 fincl5 = 'OMEGA500','PRECT','U200','U850','FLUT'
 fincl6 = 'PRECT','TMQ'
 fincl7 = 'PS','Q','T','Z3','CLOUD','CONCLD','CLDICE','CLDLIQ','FREQR','REI','REL','PRECT','TMQ','PRECC','TREFHT','QREFHT','OMEGA','CLDTOT','LHFLX','SHFLX','FLDS','FSDS','FLNS','FSNS','FLNSC','FSDSC','FSNSC','AODVIS','AODABS','LS_FLXPRC','LS_FLXSNW','LS_REFFRAIN','ZMFLXPRC','ZMFLXSNW','CCN1','CCN2','CCN3','CCN4','CCN5','num_a1','num_a2','num_a3','num_a4','so4_a1','so4_a2','so4_a3','AREL','TGCLDLWP','AQRAIN','ANRAIN','FREQR','PRECL','RELHUM' 
 fincl7lonlat='262.5e_36.6n','204.6e_71.3n','147.4e_2.0s','166.9e_0.5s','130.9e_12.4s','331.97e_39.09n'
 fincl8 = 'cdnc', 'lwp', 'iwp', 'lcc', 'icc', 'clt', 'cod', 'ccn', 'ttop', 'OMEGA500', 'OMEGA700', 'TH7001000', 'U850', 'V850', 'SOLIN', 'FSNT', 'FSNTOA', 'FSUTOA', 'FSUTOA_d1', 'FSUTOAC', 'FSUTOAC_d1', 'FLUT', 'FLNT', 'FLUTC', 'FLNTC', 'FSNSC', 'FSDSC', 'CLDLOW_CAL', 'CLDMED_CAL', 'CLDHGH_CAL'

 fexcl1 = 'astem_negval_1_1', 'astem_negval_1_2', 'astem_negval_1_3', 'astem_negval_1_4', 
          'astem_negval_2_1', 'astem_negval_2_2', 'astem_negval_2_3', 'astem_negval_2_4',
          'astem_negval_3_1', 'astem_negval_3_2', 'astem_negval_3_3', 'astem_negval_3_4',
          'astem_negval_4_1', 'astem_negval_4_2', 'astem_negval_4_3', 'astem_negval_4_4',
          'astem_negval_5_1', 'astem_negval_5_2', 'astem_negval_5_3', 'astem_negval_5_4',
          'pH_valid_bin_1',   'pH_valid_bin_2',   'pH_valid_bin_3',   'pH_valid_bin_4',   'pH_valid_bin_5', 
          'Hplus_valid_bin_1','Hplus_valid_bin_2','Hplus_valid_bin_3','Hplus_valid_bin_4','Hplus_valid_bin_5',
          'bc_a1_2', 'dst_a1_2', 'dst_a3_2', 'ncl_a1_2', 'ncl_a2_2', 'ncl_a3_2', 'pom_a1_2', 
          'so4_a1_2', 'so4_a2_2', 'so4_a3_2', 'soa_a1_2', 'soa_a2_2',
          'AQ_bc_a1',  'AQ_pom_a1', 'AQ_soa_a1', 'AQ_mom_a1', 'AQ_so4_a1', 'AQ_nh4_a1', 'AQ_no3_a1', 'AQ_dst_a1', 'AQ_ncl_a1', 'AQ_ca_a1', 'AQ_co3_a1', 'AQ_cl_a1',
          'AQ_soa_a2', 'AQ_mom_a2', 'AQ_so4_a2', 'AQ_nh4_a2', 'AQ_no3_a2', 'AQ_ncl_a2', 'AQ_cl_a2',
          'AQ_bc_a3',  'AQ_pom_a3', 'AQ_soa_a3', 'AQ_mom_a3', 'AQ_so4_a3', 'AQ_nh4_a3', 'AQ_no3_a3', 'AQ_dst_a3', 'AQ_ncl_a3', 'AQ_ca_a3', 'AQ_co3_a3', 'AQ_cl_a3',
          'AQ_bc_a4',  'AQ_pom_a4', 'AQ_mom_a4',
          'AQ_bc_c1',  'AQ_pom_c1', 'AQ_soa_c1', 'AQ_mom_c1', 'AQ_dst_c1', 'AQ_ncl_c1', 'AQ_ca_c1',
          'AQ_soa_c2', 'AQ_mom_c2', 'AQ_ncl_c2',
          'AQ_bc_c3',  'AQ_pom_c3', 'AQ_soa_c3', 'AQ_mom_c3', 'AQ_dst_c3', 'AQ_ncl_c3', 'AQ_ca_c3',
          'AQ_bc_c4',  'AQ_pom_c4', 'AQ_mom_c4', 'P3_mtend_NUMLIQ','P3_mtend_NUMRAIN','P3_mtend_Q','P3_mtend_TH','P3_nc2ni_immers_frz_tend',
	  'P3_nc2nr_autoconv_tend', 'P3_nc_accret_tend','P3_nc_collect_tend','P3_nc_nuceat_tend','P3_nc_selfcollect_tend',
	  'P3_ncautr','P3_ncshdc', 'P3_ni2nr_melt_tend','P3_ni_nucleat_tend','P3_ni_selfcollect_tend','P3_ni_sublim_tend',
	  'P3_nr2ni_immers_frz_tend', 'P3_nr_collect_tend','P3_nr_evap_tend','P3_nr_ice_shed_tend','P3_nr_selfcollect_tend',
	  'P3_qc2qi_hetero_frz_tend', 'P3_qc2qr_accret_tend','P3_qc2qr_autoconv_tend','P3_qc2qr_ice_shed_tend','P3_qccol','P3_qccon','P3_qcevp',
	  'P3_qcnuc','P3_qi2qr_melt_tend','P3_qi2qv_sublim_tend','P3_qidep','P3_qinuc','P3_qr2qi_immers_frz_tend',
	  'P3_qr2qv_evap_tend','P3_qrcol','P3_qwgrth','P3_sed_CLDICE','P3_sed_CLDLIQ','P3_sed_CLDRAIN','P3_sed_NUMICE',
	  'P3_sed_NUMLIQ','P3_sed_NUMRAIN'

 do_aerocom_ind3      = .true.
 tropopause_output_all = .true.
 tropopause_e90_thrd    = 80.0e-9

 history_gaschmbudget_2D = .true.
 history_gaschmbudget_2D_levels = .true.
 history_UCIgaschmbudget_2D = .true.
 history_UCIgaschmbudget_2D_levels = .true.
 gaschmbudget_2D_L1_s =  1
 gaschmbudget_2D_L1_e = 26
 gaschmbudget_2D_L2_s = 27
 gaschmbudget_2D_L2_e = 38
 gaschmbudget_2D_L3_s = 39
 gaschmbudget_2D_L3_e = 58
 gaschmbudget_2D_L4_s = 59
 gaschmbudget_2D_L4_e = 72
 
 history_aero_optics    = .true.
 history_aerosol        = .true.
 history_amwg           = .true.
 history_budget         = .true.
 history_verbose        = .true.

 cosp_lite = .true.

 zmconv_microp = .true.    
 zmconv_clos_dyn_adj = .true.     
 zmconv_MCSP_heat_coeff = 0.3
 zmconv_tpert_fix = .true.

 !Tunings in ZM and P3
 zmconv_ke=2.5e-6
 p3_wbf_coeff=1.0

 prescribed_volcaero_file = ''
 prescribed_volcaero_datapath = ''

 tracer_cnst_cycle_yr           = 1995
 tracer_cnst_datapath           = '${input_data_dir}/atm/cam/chem/methane/'
 tracer_cnst_file               = 'ch4_oxid_1.9x2.5_L26_1990-1999clim.c090804.nc'
 tracer_cnst_filelist           = ''
 tracer_cnst_specifier          = 'CH4','cnst_NO3:NO3', 'cnst_OH:OH'
 tracer_cnst_type               = 'CYCLICAL'

 linoz_psc_t = 198.0

 sad_file               = '${input_data_dir}/atm/waccm/sulf/SAD_SULF_1849-2100_1.9x2.5_c090817.nc'
 sad_type     = 'SERIAL' 

 drydep_list = 'O3','H2O2','CH2O','CH3OOH','NO','NO2','HNO3','HO2NO2','PAN','CO','CH3COCH3','C2H5OOH','CH3CHO','H2SO4','SO2','NO3','N2O5','NH3'

 gas_wetdep_list                = 'C2H5OOH','CH2O','CH3CHO','CH3OOH','H2O2','H2SO4','HNO3','HO2NO2','SO2','NH3','HCL','SOAG0','SOAG15','SOAG24','SOAG35','SOAG34','SOAG33','SOAG32','SOAG31'
 gas_wetdep_method              = 'NEU'
 
 ext_frc_specifier              = 'NO2    -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/chem_gases/2degrees/emissions-cmip6_NO2_aircraft_vertical_1750-2015_1.9x2.5_c20170608.nc',
         'SO2    -> ${MY_INPUT_DATA_PATH}/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_so2_elev_1850-2014_c180205_kzm_1850_2014_volcano.nc',
         'SOAG0  -> ${MY_INPUT_DATA_PATH}/cam/chem/emis/test/SOC_ELEV_CEDS_1985_2014_QZRNGDAMIP_F4.nc',
         'bc_a4  -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_bc_a4_elev_1850-2014_c180205.nc',
         'num_a1 -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_num_a1_elev_1850-2014_c180205.nc',
         'num_a2 -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_num_a2_elev_1850-2014_c180205.nc',
         'num_a4 -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_num_a4_elev_1850-2014_c180205.nc',
         'pom_a4 -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_pom_a4_elev_1850-2014_c180205.nc',
         'so4_a1 -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_so4_a1_elev_1850-2014_c180205.nc',
         'so4_a2 -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_so4_a2_elev_1850-2014_c180205.nc' 
 ext_frc_type           = 'INTERP_MISSING_MONTHS'
 srf_emis_specifier             = 'C2H4     -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/chem_gases/2degrees/emissions-cmip6_e3sm_C2H4_surface_1850-2014_1.9x2.5_c20210323.nc', 
         'C2H6     -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/chem_gases/2degrees/emissions-cmip6_e3sm_C2H6_surface_1850-2014_1.9x2.5_c20210323.nc', 
         'C3H8     -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/chem_gases/2degrees/emissions-cmip6_e3sm_C3H8_surface_1850-2014_1.9x2.5_c20210323.nc',
         'CH2O     -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/chem_gases/2degrees/emissions-cmip6_e3sm_CH2O_surface_1850-2014_1.9x2.5_c20210323.nc',
         'CH3CHO   -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/chem_gases/2degrees/emissions-cmip6_e3sm_CH3CHO_surface_1850-2014_1.9x2.5_c20210323.nc',
         'CH3COCH3 -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/chem_gases/2degrees/emissions-cmip6_e3sm_CH3COCH3_surface_1850-2014_1.9x2.5_c20210323.nc',
         'CO       -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/chem_gases/2degrees/emissions-cmip6_e3sm_CO_surface_1850-2014_1.9x2.5_c20210323.nc',       
         'ISOP     -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/chem_gases/2degrees/emissions-cmip6_e3sm_ISOP_surface_1850-2014_1.9x2.5_c20210323.nc',
         'C10H16   -> ${MY_INPUT_DATA_PATH}/cam/chem/emis/CMIP6_emissions_1750_2015_2deg_FINAL/emissions-cmip6_e3sm_MTERP_surface_1850-2014_1.9x2.5_c20220426.nc',         
         'SOAG0    -> ${MY_INPUT_DATA_PATH}/cam/chem/emis/test/SOC_CEDS_1985_2014_QZRNGDAMIP_F4.nc',
         'NH3      -> ${MY_INPUT_DATA_PATH}/cam/chem/emis/CMIP6_emissions_1750_2015_2deg_FINAL/emissions-cmip6_e3sm_NH3_surface_1850-2014_1.9x2.5_c20220426.nc',
         'NO       -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/chem_gases/2degrees/emissions-cmip6_e3sm_NO_surface_1850-2014_1.9x2.5_c20220425.nc',    
         'DMS      -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/DMSflux.1850-2100.1deg_latlon_conserv.POPmonthlyClimFromACES4BGC_c20160727.nc',
         'SO2      -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_so2_surf_1850-2014_c180205.nc',
         'bc_a4    -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_bc_a4_surf_1850-2014_c180205.nc',
         'num_a1   -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_num_a1_surf_1850-2014_c180205.nc',
         'num_a2   -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_num_a2_surf_1850-2014_c180205.nc',
         'num_a4   -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_num_a4_surf_1850-2014_c180205.nc',
         'pom_a4   -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_pom_a4_surf_1850-2014_c180205.nc',
         'so4_a1   -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_so4_a1_surf_1850-2014_c180205.nc',
         'so4_a2   -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/DECK_ne30/cmip6_mam4_so4_a2_surf_1850-2014_c180205.nc',
         'E90      -> ${input_data_dir}/atm/cam/chem/trop_mozart_aero/emis/chem_gases/2degrees/emissions_E90_surface_1750-2015_1.9x2.5_c20210408.nc'
 srf_emis_type          = 'INTERP_MISSING_MONTHS'

 mode_defs = 'mam5_mode1:accum:=', 'A:num_a1:N:num_c1:num_mr:+',
         'A:so4_a1:N:so4_c1:sulfate:${input_data_dir}/atm/cam/physprops/sulfate_rrtmg_c080918.nc:+',
         'A:pom_a1:N:pom_c1:p-organic:${input_data_dir}/atm/cam/physprops/ocpho_rrtmg_c130709.nc:+',
         'A:soa_a1:N:soa_c1:s-organic:${input_data_dir}/atm/cam/physprops/ocphi_rrtmg_c100508.nc:+',
         'A:bc_a1:N:bc_c1:black-c:${input_data_dir}/atm/cam/physprops/bcpho_rrtmg_c100508.nc:+',
         'A:dst_a1:N:dst_c1:dust:${input_data_dir}/atm/cam/physprops/dust_aeronet_rrtmg_c141106.nc:+',
         'A:ncl_a1:N:ncl_c1:seasalt:${input_data_dir}/atm/cam/physprops/ssam_rrtmg_c100508.nc:+',
         'A:mom_a1:N:mom_c1:m-organic:${input_data_dir}/atm/cam/physprops/poly_rrtmg_c130816.nc:+',
         'A:nh4_a1:N:nh4_c1:ammonium:${input_data_dir}/atm/cam/physprops/sulfate_rrtmg_c080918.nc:+',
         'A:no3_a1:N:no3_c1:nitrate:${MY_INPUT_DATA_PATH}/cam/physprops/nitrate_rrtmg_c210412.nc:+',
         'A:ca_a1:N:ca_c1:calcium:${input_data_dir}/atm/cam/physprops/dust_aeronet_rrtmg_c141106.nc:+',
         'A:co3_a1:N:co3_c1:carbonate:${input_data_dir}/atm/cam/physprops/dust_aeronet_rrtmg_c141106.nc:+',
         'A:cl_a1:N:cl_c1:chloride:${input_data_dir}/atm/cam/physprops/ssam_rrtmg_c100508.nc',
         'mam5_mode2:aitken:=', 'A:num_a2:N:num_c2:num_mr:+',
         'A:so4_a2:N:so4_c2:sulfate:${input_data_dir}/atm/cam/physprops/sulfate_rrtmg_c080918.nc:+',
         'A:soa_a2:N:soa_c2:s-organic:${input_data_dir}/atm/cam/physprops/ocphi_rrtmg_c100508.nc:+',
         'A:ncl_a2:N:ncl_c2:seasalt:${input_data_dir}/atm/cam/physprops/ssam_rrtmg_c100508.nc:+',
         'A:mom_a2:N:mom_c2:m-organic:${input_data_dir}/atm/cam/physprops/poly_rrtmg_c130816.nc:+',
         'A:nh4_a2:N:nh4_c2:ammonium:${input_data_dir}/atm/cam/physprops/sulfate_rrtmg_c080918.nc:+',
         'A:no3_a2:N:no3_c2:nitrate:${MY_INPUT_DATA_PATH}/cam/physprops/nitrate_rrtmg_c210412.nc:+',
         'A:cl_a2:N:cl_c2:chloride:${input_data_dir}/atm/cam/physprops/ssam_rrtmg_c100508.nc',
         'mam5_mode3:coarse:=', 'A:num_a3:N:num_c3:num_mr:+',
         'A:dst_a3:N:dst_c3:dust:${input_data_dir}/atm/cam/physprops/dust_aeronet_rrtmg_c141106.nc:+',
         'A:ncl_a3:N:ncl_c3:seasalt:${input_data_dir}/atm/cam/physprops/ssam_rrtmg_c100508.nc:+',
         'A:so4_a3:N:so4_c3:sulfate:${input_data_dir}/atm/cam/physprops/sulfate_rrtmg_c080918.nc:+',
         'A:bc_a3:N:bc_c3:black-c:${input_data_dir}/atm/cam/physprops/bcpho_rrtmg_c100508.nc:+',
         'A:pom_a3:N:pom_c3:p-organic:${input_data_dir}/atm/cam/physprops/ocpho_rrtmg_c130709.nc:+',
         'A:soa_a3:N:soa_c3:s-organic:${input_data_dir}/atm/cam/physprops/ocphi_rrtmg_c100508.nc:+',
         'A:mom_a3:N:mom_c3:m-organic:${input_data_dir}/atm/cam/physprops/poly_rrtmg_c130816.nc:+',
         'A:nh4_a3:N:nh4_c3:ammonium:${input_data_dir}/atm/cam/physprops/sulfate_rrtmg_c080918.nc:+',
         'A:no3_a3:N:no3_c3:nitrate:${MY_INPUT_DATA_PATH}/cam/physprops/nitrate_rrtmg_c210412.nc:+',
         'A:ca_a3:N:ca_c3:calcium:${input_data_dir}/atm/cam/physprops/dust_aeronet_rrtmg_c141106.nc:+',
         'A:co3_a3:N:co3_c3:carbonate:${input_data_dir}/atm/cam/physprops/dust_aeronet_rrtmg_c141106.nc:+',
         'A:cl_a3:N:cl_c3:chloride:${input_data_dir}/atm/cam/physprops/ssam_rrtmg_c100508.nc',
         'mam5_mode4:primary_carbon:=', 'A:num_a4:N:num_c4:num_mr:+',
         'A:pom_a4:N:pom_c4:p-organic:${input_data_dir}/atm/cam/physprops/ocpho_rrtmg_c130709.nc:+',
         'A:bc_a4:N:bc_c4:black-c:${input_data_dir}/atm/cam/physprops/bcpho_rrtmg_c100508.nc:+',
         'A:mom_a4:N:mom_c4:m-organic:${input_data_dir}/atm/cam/physprops/poly_rrtmg_c130816.nc',
         'mam5_mode5:strat_coarse:=', 'A:num_a5:N:num_c5:num_mr:+',
         'A:so4_a5:N:so4_c5:sulfate:${input_data_dir}/atm/cam/physprops/sulfate_rrtmg_c080918.nc'
 
 rad_climate            = 'A:H2OLNZ:H2O', 'N:O2:O2', 'N:CO2:CO2',
         'A:O3:O3', 'A:N2OLNZ:N2O', 'A:CH4LNZ:CH4',
         'N:CFC11:CFC11', 'N:CFC12:CFC12', 
         'M:mam5_mode1:${input_data_dir}/atm/cam/physprops/mam4_mode1_rrtmg_aeronetdust_c141106.nc',
         'M:mam5_mode2:${input_data_dir}/atm/cam/physprops/mam4_mode2_rrtmg_c130628.nc', 
         'M:mam5_mode3:${input_data_dir}/atm/cam/physprops/mam4_mode3_rrtmg_aeronetdust_c141106.nc',
         'M:mam5_mode4:${input_data_dir}/atm/cam/physprops/mam4_mode4_rrtmg_c130628.nc',
         'M:mam5_mode5:${MY_INPUT_DATA_PATH}/cam/physprops/mam4_mode3_rrtmg_aeronetdust_sig1.2_dgnl.40_c150219_ke.nc'
 rad_diag_1 = 'A:H2OLNZ:H2O','N:O2:O2','N:CO2:CO2','A:O3:O3','A:N2OLNZ:N2O','A:CH4LNZ:CH4','N:CFC11:CFC11','N:CFC12:CFC12'

 dust_emis_fact         =  11.80D0
 seasalt_emis_scale     =  0.50D0

 cflx_cpl_opt = 2

 megan_factors_file = '${input_data_dir}/atm/cam/chem/trop_mozart/emis/megan21_emis_factors_c20130304.nc'
 megan_specifier = 'C10H16 = myrcene + sabinene + limonene + carene_3 + ocimene_t_b + pinene_b + pinene_a + 2met_styrene + cymene_p + cymene_o + phellandrene_a + thujene_a + terpinene_a + terpinene_g + terpinolene + phellandrene_b + camphene + bornene + fenchene_a + ocimene_al + ocimene_c_b'
EOF

cat << EOF >> user_nl_elm
 check_finidat_year_consistency = .false.
 check_dynpft_consistency = .false.
 fsurdat = '${input_data_dir}/lnd/clm2/surfdata_map/surfdata_ne30pg2_simyr1850_c210402.nc'
 flanduse_timeseries = '${input_data_dir}/lnd/clm2/surfdata_map/landuse.timeseries_ne30np4.pg2_hist_simyr1850-2015_c210113.nc'
EOF

}

# =====================================
# Customize MPAS stream files if needed
# =====================================

patch_mpas_streams() {

echo

}

# =====================================================
# Custom PE layout: custom-N where N is number of nodes
# =====================================================

custom_pelayout() {

if [[ ${PELAYOUT} == custom-* ]];
then
    echo $'\n CUSTOMIZE PROCESSOR CONFIGURATION:'

    # Number of cores per node (machine specific)
    if [ "${MACHINE}" == "chrysalis" ]; then
        ncore=64
    elif [ "${MACHINE}" == "compy" ]; then
        ncore=40
    else
        echo 'ERROR: MACHINE = '${MACHINE}' is not supported for custom PE layout.' 
        exit 400
    fi

    # Extract number of nodes
    tmp=($(echo ${PELAYOUT} | tr "-" " "))
    nnodes=${tmp[1]}

    # Customize
    pushd ${CASE_SCRIPTS_DIR}
    ./xmlchange NTASKS=$(( $nnodes * $ncore ))
    ./xmlchange NTHRDS=1
    ./xmlchange MAX_MPITASKS_PER_NODE=$ncore
    ./xmlchange MAX_TASKS_PER_NODE=$ncore
    popd

fi

}

######################################################
### Most users won't need to change anything below ###
######################################################

#-----------------------------------------------------
fetch_code() {

    if [ "${do_fetch_code,,}" != "true" ]; then
        echo $'\n----- Skipping fetch_code -----\n'
        return
    fi

    echo $'\n----- Starting fetch_code -----\n'
    local path=${CODE_ROOT}
    local repo=e3sm

    echo "Cloning $repo repository branch $BRANCH under $path"
    if [ -d "${path}" ]; then
        echo "ERROR: Directory already exists. Not overwriting"
        exit 20
    fi
    mkdir -p ${path}
    pushd ${path}

    # This will put repository, with all code
    git clone git@github.com:E3SM-Project/${repo}.git .
    
    # Setup git hooks
    rm -rf .git/hooks
    git clone git@github.com:E3SM-Project/E3SM-Hooks.git .git/hooks
    git config commit.template .git/hooks/commit.template

    # Bring in all submodule components
    git submodule update --init --recursive

    # Check out desired branch
    git checkout ${BRANCH}

    # Custom addition
    if [ "${CHERRY}" != "" ]; then
        echo ----- WARNING: adding git cherry-pick -----
        for commit in "${CHERRY[@]}"
        do
            echo ${commit}
            git cherry-pick ${commit}
        done
        echo -------------------------------------------
    fi

    # Bring in all submodule components
    git submodule update --init --recursive

    popd
}

#-----------------------------------------------------
create_newcase() {

    if [ "${do_create_newcase,,}" != "true" ]; then
        echo $'\n----- Skipping create_newcase -----\n'
        return
    fi

    echo $'\n----- Starting create_newcase -----\n'

    if [[ ${PELAYOUT} == custom-* ]];
    then
        layout="M" # temporary placeholder for create_newcase
    else
        layout=${PELAYOUT}

    fi
    ${CODE_ROOT}/cime/scripts/create_newcase \
        --case ${CASE_NAME} \
        --output-root ${CASE_ROOT} \
        --script-root ${CASE_SCRIPTS_DIR} \
        --handle-preexisting-dirs u \
        --compset ${COMPSET} \
        --res ${RESOLUTION} \
        --machine ${MACHINE} \
        --project ${PROJECT} \
        --walltime ${WALLTIME} \
        --pecount ${layout}

    if [ $? != 0 ]; then
      echo $'\nNote: if create_newcase failed because sub-directory already exists:'
      echo $'  * delete old case_script sub-directory'
      echo $'  * or set do_newcase=false\n'
      exit 35
    fi

}

#-----------------------------------------------------
case_setup() {

    if [ "${do_case_setup,,}" != "true" ]; then
        echo $'\n----- Skipping case_setup -----\n'
        return
    fi

    echo $'\n----- Starting case_setup -----\n'
    pushd ${CASE_SCRIPTS_DIR}

    # Source Mods copy .F90 files to src.*
    # cp ${HOME}/source_files/E3SMv2_UCI-MZT-MSC_20220629/mo_gas_phase_chemdr.F90   ${CASE_SCRIPTS_DIR}/SourceMods/src.eam/mo_gas_phase_chemdr.F90

    # Setup some CIME directories
    ./xmlchange EXEROOT=${CASE_BUILD_DIR}
    ./xmlchange RUNDIR=${CASE_RUN_DIR}

    # Short term archiving
    ./xmlchange DOUT_S=${DO_SHORT_TERM_ARCHIVING^^}
    ./xmlchange DOUT_S_ROOT=${CASE_ARCHIVE_DIR}

    # Build with COSP, except for a data atmosphere (datm)
    if [ `./xmlquery --value COMP_ATM` == "datm"  ]; then 
      echo $'\nThe specified configuration uses a data atmosphere, so cannot activate COSP simulator\n'
    else
      echo $'\nConfiguring E3SM to use the COSP simulator\n'
      ./xmlchange --id CAM_CONFIG_OPTS --append --val='-cosp'
    fi

    # Extracts input_data_dir in case it is needed for user edits to the namelist later
    local input_data_dir=`./xmlquery DIN_LOC_ROOT --value`

    # MW changing chemistry mechanism
    local usr_mech_infile="/lcrc/group/e3sm/ac.mwu/archive/20221103.v2.LR.amip.NGD_v3atm.chrysalis/case_scripts/Buildconf/eamconf/chem_mech.in"
    echo 'CRT/MW Changing chemistry to :'${usr_mech_infile} 
    ./xmlchange --id CAM_CONFIG_OPTS --append --val='-microphys p3 -chem superfast_mam5_resus_mom_vbs_mosaic -mosaic -vbs -usr_mech_infile '${usr_mech_infile}

    # Custom user_nl
    user_nl

    # Finally, run CIME case.setup
    ./case.setup --reset

    popd
}

#-----------------------------------------------------
case_build() {

    pushd ${CASE_SCRIPTS_DIR}

    # do_case_build = false
    if [ "${do_case_build,,}" != "true" ]; then

        echo $'\n----- case_build -----\n'

        if [ "${OLD_EXECUTABLE}" == "" ]; then
            # Ues previously built executable, make sure it exists
            if [ -x ${CASE_BUILD_DIR}/e3sm.exe ]; then
                echo 'Skipping build because $do_case_build = '${do_case_build}
            else
                echo 'ERROR: $do_case_build = '${do_case_build}' but no executable exists for this case.'
                exit 297
            fi
        else
            # If absolute pathname exists and is executable, reuse pre-exiting executable
            if [ -x ${OLD_EXECUTABLE} ]; then
                echo 'Using $OLD_EXECUTABLE = '${OLD_EXECUTABLE}
                cp -fp ${OLD_EXECUTABLE} ${CASE_BUILD_DIR}/
            else
                echo 'ERROR: $OLD_EXECUTABLE = '$OLD_EXECUTABLE' does not exist or is not an executable file.'
                exit 297
            fi
        fi
        echo 'WARNING: Setting BUILD_COMPLETE = TRUE.  This is a little risky, but trusting the user.'
        ./xmlchange BUILD_COMPLETE=TRUE

    # do_case_build = true
    else

        echo $'\n----- Starting case_build -----\n'

        # Turn on debug compilation option if requested
        if [ "${DEBUG_COMPILE^^}" == "TRUE" ]; then
            ./xmlchange DEBUG=${DEBUG_COMPILE^^}
        fi

        # Run CIME case.build
        ./case.build

    fi

    # Some user_nl settings won't be updated to *_in files under the run directory
    # Call preview_namelists to make sure *_in and user_nl files are consistent.
    echo $'\n----- Preview namelists -----\n'
    ./preview_namelists

    popd
}

#-----------------------------------------------------
runtime_options() {

    echo $'\n----- Starting runtime_options -----\n'
    pushd ${CASE_SCRIPTS_DIR}

    # Set simulation start date
    ./xmlchange RUN_STARTDATE=${START_DATE}

    # Segment length
    ./xmlchange STOP_OPTION=${STOP_OPTION,,},STOP_N=${STOP_N}

    # Restart frequency
    ./xmlchange REST_OPTION=${REST_OPTION,,},REST_N=${REST_N}

    # Coupler history
    ./xmlchange HIST_OPTION=${HIST_OPTION,,},HIST_N=${HIST_N}

    # Coupler budgets (always on)
    ./xmlchange BUDGETS=TRUE

    # Set resubmissions
    if (( RESUBMIT > 0 )); then
        ./xmlchange RESUBMIT=${RESUBMIT}
    fi

    # Run type
    # Start from default of user-specified initial conditions
    if [ "${MODEL_START_TYPE,,}" == "initial" ]; then
        ./xmlchange RUN_TYPE="startup"
        ./xmlchange CONTINUE_RUN="FALSE"

    # Continue existing run
    elif [ "${MODEL_START_TYPE,,}" == "continue" ]; then
        ./xmlchange CONTINUE_RUN="TRUE"

    elif [ "${MODEL_START_TYPE,,}" == "branch" ] || [ "${MODEL_START_TYPE,,}" == "hybrid" ]; then
        ./xmlchange RUN_TYPE=${MODEL_START_TYPE,,}
        ./xmlchange GET_REFCASE=${GET_REFCASE}
        ./xmlchange RUN_REFDIR=${RUN_REFDIR}
        ./xmlchange RUN_REFCASE=${RUN_REFCASE}
        ./xmlchange RUN_REFDATE=${RUN_REFDATE}
        echo 'Warning: $MODEL_START_TYPE = '${MODEL_START_TYPE} 
        echo '$RUN_REFDIR = '${RUN_REFDIR}
        echo '$RUN_REFCASE = '${RUN_REFCASE}
        echo '$RUN_REFDATE = '${START_DATE}
    else
        echo 'ERROR: $MODEL_START_TYPE = '${MODEL_START_TYPE}' is unrecognized. Exiting.'
        exit 380
    fi

    # Patch mpas streams files
    patch_mpas_streams

    popd
}

#-----------------------------------------------------
case_submit() {

    if [ "${do_case_submit,,}" != "true" ]; then
        echo $'\n----- Skipping case_submit -----\n'
        return
    fi

    echo $'\n----- Starting case_submit -----\n'
    pushd ${CASE_SCRIPTS_DIR}
    
    # Run CIME case.submit
    ./case.submit

    popd
}

#-----------------------------------------------------
copy_script() {

    echo $'\n----- Saving run script for provenance -----\n'

    local script_provenance_dir=${CASE_SCRIPTS_DIR}/run_script_provenance
    mkdir -p ${script_provenance_dir}
    local this_script_name=`basename $0`
    local script_provenance_name=${this_script_name}.`date +%Y%m%d-%H%M%S`
    cp -vp ${this_script_name} ${script_provenance_dir}/${script_provenance_name}

}

#-----------------------------------------------------
# Silent versions of popd and pushd
pushd() {
    command pushd "$@" > /dev/null
}
popd() {
    command popd "$@" > /dev/null
}

# Now, actually run the script
#-----------------------------------------------------
main

