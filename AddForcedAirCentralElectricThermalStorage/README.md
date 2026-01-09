

###### (Automatically generated documentation)

# Add Forced Air Central Electric Thermal Storage

## Description
This measures adds a forced-air central Electric Thermal Storage (ETS) device to the current building model.

## Modeler Description
Code developped M. Mathieu Laroche, M.Sc. Supervised by Mme. Katherine DAvignon, Ph.D & Danielle Monfet, PhD, with the support of M. François Laurencelle, Ph.D.

## Measure Type
ModelMeasure

## Taxonomy


## Arguments


### Enter device name and number
This is the unique identifier of the device. Use distinct names.
**Name:** atc_name,
**Type:** String,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Select Loop:
Error: No loops were found
**Name:** selected_loop,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** 


### Select furnace:
Error: No furnaces were found
**Name:** selected_furnace,
**Type:** Choice,
**Units:** ,
**Required:** false,
**Model Dependent:** false

**Choice Display Names** 


### Location of storage device:
This selects where the storage device is mounted
**Name:** storage_placement,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["Upstream", "Downstream"]


### Select Charging Schedule:
Error: No schedules were found elsewhere in the model
**Name:** selected_charging_schedule,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** 


### Select Discharging Schedule:
Error: No schedules were found elsewhere in the model
**Name:** selected_discharging_schedule,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** 


### Select Maximum Allowable Bldg Elec Demand Schedule:
Error: No schedules were found elsewhere in the model
**Name:** selected_pbldgmax_schedule,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** 


### Select Outlet Air Temperature Setpoint Schedule:
Error: No schedules were found elsewhere in the model
**Name:** selected_outletairtemp_schedule,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** 


### Enter characterized storage capacitance C [kJ/K]

**Name:** sto_cap,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Enter characterized heat loss coefficient UAeff [W/K]:

**Name:** ua_eff,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Enter discharge regression slope alpha [kW/K]:

**Name:** alpha,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Enter discharge regression intercept beta [kW]:

**Name:** beta,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Enter device maximum discharge rate [kW]:

**Name:** pheat_max,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Enter device maximum electrical charging rate [kW]:

**Name:** pelec_max,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Enter the Initial Brick Temperature [°C]:

**Name:** initial_temperature,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Enter the Maximum Brick Target Temperature [°C]:

**Name:** storage_Temperature_High_Limit,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Enter the Minimum Outdoor Temperature [°C]:

**Name:** minimum_Outdoor_Temperature,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Enter the Minimum Brick Target Temperature [°C]:

**Name:** storage_Temperature_Low_Limit,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Enter the Maximum Outdoor Temperature [°C]:

**Name:** maximum_Outdoor_Temperature,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Enter the brick core temperature deadband [±X °C]:

**Name:** brick_temp_deadband,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Enter device inlet maximum air volumetric flow rate [m3/s]:

**Name:** vol_flow_rate,
**Type:** Double,
**Units:** ,
**Required:** true,
**Model Dependent:** false


### Select ambient zone:
Error: No zones were found
**Name:** selected_zone,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** 


### Select Reporting Frequency for New Output Variables
This will not change reporting frequency for existing output variables in the model.
**Name:** report_freq,
**Type:** Choice,
**Units:** ,
**Required:** false,
**Model Dependent:** false

**Choice Display Names** ["Detailed", "Timestep", "Hourly", "Daily", "Monthly", "RunPeriod"]


### Level of output reporting related to the EMS internal variables that are available.

**Name:** internal_variable_availability_dictionary_reporting,
**Type:** Choice,
**Units:** ,
**Required:** true,
**Model Dependent:** false

**Choice Display Names** ["None", "NotByUniqueKeyNames", "Verbose"]






