class AddForcedAirCentralElectricThermalStorage < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Add Forced Air Central Electric Thermal Storage'
  end

  # human readable description
  def description
    return 'This measures adds a forced-air central Electric Thermal Storage (ETS) device to the current building model.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Code developped Mathieu Laroche, M.Sc. Supervised by Katherine DAvignon, Ph.D & Danielle Monfet, Ph.D, based on the work of Younes, DAvignon, & Laurencelle, F. (2023) https://doi.org/10.5281/zenodo.10215082'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

	# Enter device name / number
	atc_name = OpenStudio::Measure::OSArgument::makeStringArgument('atc_name', true)
	atc_name.setDisplayName('Enter device name and number')
	atc_name.setDescription('This is the unique identifier of the device. Use distinct names.')
	atc_name.setDefaultValue('ETS1')
	args << atc_name

	# Select Which loop to add ATC to
	air_loops = model.getAirLoopHVACs
	loop_choices = OpenStudio::StringVector.new
	air_loops.each do |loop|
      loop_choices << loop.name.to_s
	end

	# Make choice argument for loop selection
	selected_loop = OpenStudio::Measure::OSArgument::makeChoiceArgument('selected_loop', loop_choices, true)
	selected_loop.setDisplayName('Select Loop:')
	selected_loop.setDescription('This is the Heating loop on which ETS will be added.')
	if !air_loops.empty?
		selected_loop.setDefaultValue(loop_choices[0])
	else
		selected_loop.setDescription('Error: No loops were found')
	end
	args << selected_loop


	#Look for central heating devices such as heating coils
	furnaces = model.getCoilHeatingElectrics
	furnace_choices = OpenStudio::StringVector.new
	furnaces.each do |furnace|
		furnace_choices << furnace.name.to_s
	end
	if !furnaces.empty?
		boolarg = true
	else
		boolarg = false
	end


	# Make choice argument for furnaces to operate alongside storage device
	selected_furnace = OpenStudio::Measure::OSArgument::makeChoiceArgument('selected_furnace', furnace_choices, boolarg)
	selected_furnace.setDisplayName('Select furnace:')
	selected_furnace.setDescription('This equipment will operate alongside the storage device.')
	if !furnaces.empty?
		selected_furnace.setDefaultValue(furnace_choices[0])
	else
		selected_furnace.setDescription('Error: No furnaces were found')
	end
    args << selected_furnace
	
	placement_choices = OpenStudio::StringVector.new
	placement_choices << 'Upstream'
	placement_choices << 'Downstream' 

	# Select placement of the storage device
	storage_placement = OpenStudio::Measure::OSArgument::makeChoiceArgument('storage_placement', placement_choices, true)
	storage_placement.setDisplayName('Location of storage device:')
	storage_placement.setDescription('This selects where the storage device is mounted')
	storage_placement.setDefaultValue('Upstream')
	args << storage_placement


	# find all schedules in model
	schedules = model.getSchedules
	schedule_choices = OpenStudio::StringVector.new
	schedules.each do |schedule|
		schedule_choices << schedule.name.to_s
	end

	# select charging authorization schedule
	selected_charging_schedule = OpenStudio::Measure::OSArgument::makeChoiceArgument('selected_charging_schedule', schedule_choices, true)
	selected_charging_schedule.setDisplayName('Select Charging Schedule:')
	selected_charging_schedule.setDescription('This schedule should contain electric charging authorizations values.')
	if !schedules.empty?
		selected_charging_schedule.setDefaultValue(schedule_choices[0])
	else
		selected_charging_schedule.setDescription('Error: No schedules were found elsewhere in the model')
	end
	args << selected_charging_schedule

	# select discharge authorizaztion schedule
	selected_discharging_schedule = OpenStudio::Measure::OSArgument::makeChoiceArgument('selected_discharging_schedule', schedule_choices, true)
	selected_discharging_schedule.setDisplayName('Select Discharging Schedule:')
	selected_discharging_schedule.setDescription('This schedule should contain heat discharging authorization values values.')
	if !schedules.empty?
		selected_discharging_schedule.setDefaultValue(schedule_choices[0])
	else
		selected_discharging_schedule.setDescription('Error: No schedules were found elsewhere in the model')
	end
	args << selected_discharging_schedule


	# select building maximum demand schedule
	selected_pbldgmax_schedule = OpenStudio::Measure::OSArgument::makeChoiceArgument('selected_pbldgmax_schedule', schedule_choices, true)
	selected_pbldgmax_schedule.setDisplayName('Select Maximum Allowable Bldg Elec Demand Schedule:')
	selected_pbldgmax_schedule.setDescription('Scheduled Maximum Allowable Bldg Elec Demand [Watts]')
	if !schedules.empty?
		selected_pbldgmax_schedule.setDefaultValue(schedule_choices[0])
	else
		selected_pbldgmax_schedule.setDescription('Error: No schedules were found elsewhere in the model')
	end
	args << selected_pbldgmax_schedule
	
	# select supply air temperature setpoint Schedule
	selected_outletairtemp_schedule = OpenStudio::Measure::OSArgument::makeChoiceArgument('selected_outletairtemp_schedule', schedule_choices, true)
	selected_outletairtemp_schedule.setDisplayName('Select Outlet Air Temperature Setpoint Schedule:')
	selected_outletairtemp_schedule.setDescription('Supply air temperature to zones [°C]')
	if !schedules.empty?
		selected_outletairtemp_schedule.setDefaultValue(schedule_choices[0])
	else
		selected_outletairtemp_schedule.setDescription('Error: No schedules were found elsewhere in the model')
	end
	args << selected_outletairtemp_schedule
	
	# Make double argument for model parameter C
	sto_cap = OpenStudio::Measure::OSArgument::makeDoubleArgument('sto_cap', true)
	sto_cap.setDisplayName('Enter characterized storage capacitance C [kJ/K]')
	sto_cap.setDefaultValue(766)
	args << sto_cap
	
	# Make double argument for model parameter ua_eff
	ua_eff = OpenStudio::Measure::OSArgument::makeDoubleArgument('ua_eff', true)
	ua_eff.setDisplayName('Enter characterized heat loss coefficient UAeff [W/K]:')
	ua_eff.setDefaultValue(2.937)
	args << ua_eff
	
	# Make double argument for model parameter Alpha
	alpha = OpenStudio::Measure::OSArgument::makeDoubleArgument('alpha', true)
	alpha.setDisplayName('Enter discharge regression slope alpha [kW/K]:')
	alpha.setDefaultValue(0.125)
	args << alpha
	
	# Make double argument for model parameter Beta
	beta = OpenStudio::Measure::OSArgument::makeDoubleArgument('beta', true)
	beta.setDisplayName('Enter discharge regression intercept beta [kW]:')
	beta.setDefaultValue(2.887)
	args << beta
	
	#Make double argument for max ETS output
	pheat_max = OpenStudio::Measure::OSArgument::makeDoubleArgument('pheat_max', true)
	pheat_max.setDisplayName('Enter device maximum discharge rate [kW]:')
	pheat_max.setDefaultValue(18)
	args << pheat_max
	
	#Make double argument for max ETS charging rate
	pelec_max = OpenStudio::Measure::OSArgument::makeDoubleArgument('pelec_max', true)
	pelec_max.setDisplayName('Enter device maximum electrical charging rate [kW]:')
	pelec_max.setDefaultValue(19.2)
	args << pelec_max

	# Make double argument for Initial Brick Temperature
	initial_temperature = OpenStudio::Measure::OSArgument::makeDoubleArgument('initial_temperature', true)
	initial_temperature.setDisplayName('Enter the Initial Brick Temperature [°C]:')
	initial_temperature.setDefaultValue(400)
	args << initial_temperature

	# Make double argument for Maximum brick core target temperature
	storage_Temperature_High_Limit = OpenStudio::Measure::OSArgument::makeDoubleArgument('storage_Temperature_High_Limit', true)
	storage_Temperature_High_Limit.setDisplayName('Enter the Maximum Brick Target Temperature [°C]:')
	storage_Temperature_High_Limit.setDefaultValue(648)
	args << storage_Temperature_High_Limit

	# Make double argument for Minimum  Outdoor air temperature
	minimum_Outdoor_Temperature = OpenStudio::Measure::OSArgument::makeDoubleArgument('minimum_Outdoor_Temperature', true)
	minimum_Outdoor_Temperature.setDisplayName('Enter the Minimum Outdoor Temperature [°C]:')
	minimum_Outdoor_Temperature.setDefaultValue(-15)
	args << minimum_Outdoor_Temperature

	# Make double argument for Minimum brick core target temperature
	storage_Temperature_Low_Limit = OpenStudio::Measure::OSArgument::makeDoubleArgument('storage_Temperature_Low_Limit', true)
	storage_Temperature_Low_Limit.setDisplayName('Enter the Minimum Brick Target Temperature [°C]:')
	storage_Temperature_Low_Limit.setDefaultValue(93)
	args << storage_Temperature_Low_Limit

	# Make double argument for Maximum outdoor air temperature
	maximum_Outdoor_Temperature = OpenStudio::Measure::OSArgument::makeDoubleArgument('maximum_Outdoor_Temperature', true)
	maximum_Outdoor_Temperature.setDisplayName('Enter the Maximum Outdoor Temperature [°C]:')
	maximum_Outdoor_Temperature.setDefaultValue(15)
	args << maximum_Outdoor_Temperature
	
	#Make double argument for brick temperature deadband
	brick_temp_deadband = OpenStudio::Measure::OSArgument::makeDoubleArgument('brick_temp_deadband', true)
	brick_temp_deadband.setDisplayName('Enter the brick core temperature deadband [±X °C]:')
	brick_temp_deadband.setDefaultValue(0)
	args << brick_temp_deadband

	# Make double argument for Maximum mass flow rate - Max flowrate of the fan at INLET of ETS
	vol_flow_rate = OpenStudio::Measure::OSArgument::makeDoubleArgument('vol_flow_rate', true)
	vol_flow_rate.setDisplayName('Enter device inlet maximum air volumetric flow rate [m3/s]:')
	vol_flow_rate.setDefaultValue(0.8)
	args << vol_flow_rate

	#look for zones to add storage device to. (For heat loss calculations)
	zones = model.getThermalZones
	zone_choices = OpenStudio::StringVector.new
	zones.each do |zone|
	  zone_choices << zone.name.to_s
	end

	# make choice argument for zone name selection
	selected_zone = OpenStudio::Measure::OSArgument::makeChoiceArgument('selected_zone', zone_choices, true)
	selected_zone.setDisplayName('Select ambient zone:')
	selected_zone.setDescription('this is the thermal zone where the equipment will be installed.')
	if !zones.empty?
		selected_zone.setDefaultValue(zone_choices[0])
	else
		selected_zone.setDescription('Error: No zones were found')
	end
	args << selected_zone

	# Make choice argument for output variable reporting frequency
	report_choices = ['Detailed', 'Timestep', 'Hourly', 'Daily', 'Monthly', 'RunPeriod']
	report_freq = OpenStudio::Measure::OSArgument::makeChoiceArgument('report_freq', report_choices, false)
	report_freq.setDisplayName('Select Reporting Frequency for New Output Variables')
	report_freq.setDescription('This will not change reporting frequency for existing output variables in the model.')
	report_freq.setDefaultValue('Timestep')
	args << report_freq

	#  make a choice argument for setting EMS InternalVariableAvailabilityDictionaryReporting value
	int_var_avail_dict_rep_chs = OpenStudio::StringVector.new
	int_var_avail_dict_rep_chs << 'None'
	int_var_avail_dict_rep_chs << 'NotByUniqueKeyNames'
	int_var_avail_dict_rep_chs << 'Verbose'
	# the 'Verbose' option is useful only for debugging and creates very large *.EDD file. Leave default input unless debugging code.
	
	internal_variable_availability_dictionary_reporting = OpenStudio::Measure::OSArgument::makeChoiceArgument('internal_variable_availability_dictionary_reporting', int_var_avail_dict_rep_chs, true)
	internal_variable_availability_dictionary_reporting.setDisplayName('Level of output reporting related to the EMS internal variables that are available.')
	internal_variable_availability_dictionary_reporting.setDefaultValue('None')
	args << internal_variable_availability_dictionary_reporting
   return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)  # Do **NOT** remove this line

    # use the built-in error checking
    unless runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

	# The following code fixes the issue of EMS objects being orphaned after deletion of a CUD object previously added by this measure.
	cud_initProgram_found = false
	model.getObjectsByName("CUD_InitProgram",false).each do |object|
	cud_initProgram_found = true
	object.remove
	end

	cud_simProgram_found = false
	model.getObjectsByName("CUD_SimProgram",false).each do |object|
	cud_simProgram_found = true
	object.remove
	end

	cud_initCallingManager_found = false
	model.getObjectsByName("CUD_InitProgramCallingManager",false).each do |object|
	cud_initCallingManager_found = true
	object.remove
	end

	cud_simCallingManager_found = false
	model.getObjectsByName("CUD_SimProgramCallingManager",false).each do |object|
	cud_simCallingManager_found = true
	object.remove
	end

	# 1. find all CUD objects
	cudobjects = model.getObjectsByType("OS:Coil:UserDefined".to_IddObjectType)
	# 2. find PCUD objects associated to ETS
	etsobjectnames = []
	cudobjects.each do |object|
	if object.name.to_s.include?("SimETS")
		etsobjectnames << object.name.to_s
	end
	end
	# 3. print the ETS devices name list
	# etsobjectnames.each do |name|
	# 	runner.registerInfo("device #{name} is in the model")
	# end
	# 4. print the size of the ETS device list
	counter = etsobjectnames.size
	runner.registerInfo("the model currently has #{counter} ETS devices: #{etsobjectnames.inspect}")

	# Find and remove all orphaned objects : EMS:GlobalVariables, EMS:sensors, EMS:actuators, EMS:InternalVariables, EMS:outputvariable, EMS:MeteredOutputVariables EMS:TrendVariables
	ems_globalvariable = model.getObjectsByType("OS:EnergyManagementSystem:GlobalVariable".to_IddObjectType)
	ems_sensors = model.getObjectsByType("OS:EnergyManagementSystem:Sensor".to_IddObjectType)
	ems_actuators = model.getObjectsByType("OS:EnergyManagementSystem:Actuator".to_IddObjectType)
	ems_internalvariables = model.getObjectsByType("OS:EnergyManagementSystem:InternalVariable".to_IddObjectType)
	ems_outputvariables = model.getObjectsByType("OS:EnergyManagementSystem:OutputVariable".to_IddObjectType)
	ems_meteredoutputvariables = model.getObjectsByType("OS:EnergyManagementSystem:MeteredOutputVariable".to_IddObjectType)
	ems_trendvariables = model.getObjectsByType("OS:EnergyManagementSystem:TrendVariable".to_IddObjectType)
	# find all ems variables
	list_of_all_ems_variables = ems_globalvariable + ems_sensors + ems_actuators + ems_internalvariables + ems_outputvariables + ems_meteredoutputvariables + ems_trendvariables
  list_of_ets_ems_variables = []
  list_of_all_ems_variables.each do |var|
		parts = var.name.to_s.split(/_/, 3)
		if parts[0] == "SimETS"
			list_of_ets_ems_variables.push(var)
		end
	end

	if !etsobjectnames.empty?
		list_of_ets_ems_variables.each do |var|
			parts = var.name.to_s.split(/_/, 3)
			etsobjectnames.each do |name|
				if name == "#{parts[0]}_#{parts[1]}"
					runner.registerInfo("The EMS variable #{var.name} is associated with an ETS object existant in the model")
				else
					runner.registerInfo("The EMS variable #{var.name} is not associated with an ETS object existant in the model. It is an orphaned object and will be deleted")
					var.remove
				end
			end
		end
	else
		list_of_ets_ems_variables.each do |var|
			runner.registerInfo("There are no ETS devices in the model.The EMS variable #{var.name} will be deleted since it is not associated with an ETS object existant in the model.")
			var.remove
		end
	end

    # assign the user inputs to variables
    atc_name = runner.getStringArgumentValue('atc_name', user_arguments)
	selected_loop = runner.getStringArgumentValue('selected_loop',user_arguments)
	furnaces = model.getCoilHeatingElectrics
	if !furnaces.empty?
		selected_furnace = runner.getStringArgumentValue('selected_furnace', user_arguments)
	else
		selected_furnace = runner.getOptionalStringArgumentValue('selected_furnace', user_arguments)
	end
	
	# Assigning double argument values
	storage_placement = runner.getStringArgumentValue('storage_placement',user_arguments)
	selected_charging_schedule = runner.getStringArgumentValue('selected_charging_schedule', user_arguments)
	selected_discharging_schedule = runner.getStringArgumentValue('selected_discharging_schedule', user_arguments)
	selected_pbldgmax_schedule = runner.getStringArgumentValue('selected_pbldgmax_schedule', user_arguments)
	selected_outletairtemp_schedule = runner.getStringArgumentValue('selected_outletairtemp_schedule', user_arguments)
	sto_cap = runner.getDoubleArgumentValue('sto_cap', user_arguments)
	ua_eff = runner.getDoubleArgumentValue('ua_eff', user_arguments)
	alpha = runner.getDoubleArgumentValue('alpha', user_arguments)
	beta = runner.getDoubleArgumentValue('beta', user_arguments)
	pheat_max = runner.getDoubleArgumentValue('pheat_max', user_arguments)
	pelec_max = runner.getDoubleArgumentValue('pelec_max', user_arguments)
	initial_temperature = runner.getDoubleArgumentValue('initial_temperature', user_arguments)
	storage_Temperature_High_Limit = runner.getDoubleArgumentValue('storage_Temperature_High_Limit', user_arguments)
	minimum_Outdoor_Temperature = runner.getDoubleArgumentValue('minimum_Outdoor_Temperature', user_arguments)
	storage_Temperature_Low_Limit = runner.getDoubleArgumentValue('storage_Temperature_Low_Limit', user_arguments)
	maximum_Outdoor_Temperature = runner.getDoubleArgumentValue('maximum_Outdoor_Temperature', user_arguments)
	brick_temp_deadband = runner.getDoubleArgumentValue('brick_temp_deadband', user_arguments)
	vol_flow_rate = runner.getDoubleArgumentValue('vol_flow_rate', user_arguments)
	selected_zone = runner.getStringArgumentValue('selected_zone',user_arguments)
	report_freq = runner.getStringArgumentValue('report_freq', user_arguments)
	
  internal_variable_availability_dictionary_reporting = runner.getStringArgumentValue('internal_variable_availability_dictionary_reporting', user_arguments)


	# Create CUD object as a proxy for an Electric Thermal Storage (ETS) device
	my_atc = OpenStudio::Model::CoilUserDefined.new(model)
  # set name (Unique identifier (UID)) for ETS device. CUD objects that simulate an ETS device are prefixed with the keyword "SimETS" in order to differentiate them from other CUD objects.
  my_atc.setName("SimETS_#{atc_name}")
  runner.registerInfo("An ETS device named #{atc_name} was added to the model")
  # clear CUD default programs -- 2 following commands do not exist
  #my_atc.resetInitializationSimulationProgram()
  #my_atc.resetOverallSimulationProgram()

	# find air loops in the model
	user_selected_loop = model.getAirLoopHVACByName(selected_loop).get
	selected_loop_name = user_selected_loop.name.get

  #Look for central heating devices such as furnaces
  furnaces = model.getCoilHeatingElectrics
  # add component to the user-selected loop
  if !furnaces.empty?
    my_furnace = model.getCoilHeatingElectricByName(selected_furnace).get
  end

  # if there is a furnace in the model, add the ETS at the specified configuration (Parallel,Upstream,Downstream) otherwise insert ETS in first node on supply branch
  if !furnaces.empty?
    if storage_placement == 'Upstream'
      my_atc.addToNode(my_furnace.inletModelObject.get.to_Node.get)
    elsif storage_placement == 'Downstream'
      my_atc.addToNode(my_furnace.outletModelObject.get.to_Node.get)
    end
  else
    my_atc.addToNode(user_selected_loop.supplyInletNode.get.to_node.get)
  end

  # add variable speed fan for the ETS
	var_fan = OpenStudio::Model::FanVariableVolume.new(model)
	var_fan.setName("#{my_atc.name}_Fan")
	var_fan.setMaximumFlowRate(vol_flow_rate)
  var_fan.setPressureRise(500)
  var_fan.setMotorEfficiency(0.9)
  var_fan.addToNode(my_atc.airInletModelObject.get.to_Node.get)

  # add component to user-defined ambient zone
  my_zone = model.getThermalZoneByName(selected_zone).get
  my_atc.setAmbientZone(my_zone)

  # Get user selected schedules (charge, discharge, peak demand)
	user_selected_charging_schedule = model.getScheduleByName(selected_charging_schedule).get
	user_selected_discharging_schedule = model.getScheduleByName(selected_discharging_schedule).get
	user_selected_pbldgmax_schedule = model.getScheduleByName(selected_pbldgmax_schedule).get
	user_selected_outletairtemp_schedule = model.getScheduleByName(selected_outletairtemp_schedule).get
	
	#The following lines remove the empty EMS programs and Calling Managers introduced by the CUD object
	empty_initProgram_found = false
	model.getObjectsByName("initializationSimulationProgram",false).each do |object|
	empty_initProgram_found = true
	object.remove
	end
	
	empty_simProgram_found = false
	model.getObjectsByName("overallSimulationProgram",false).each do |object|
	empty_simProgram_found = true
	object.remove
	end
	
	empty_initCallingManager_found = false
	model.getObjectsByName("modelSetupandSizingProgramCallingManager",false).each do |object|
	empty_initCallingManager_found = true
	object.remove
	end
	
	empty_simCallingManager_found = false
	model.getObjectsByName("overallModelSimulationProgramCallingManager",false).each do |object|
	empty_simCallingManager_found = true
	object.remove
	end

  #-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
                                                                                                          # Get CUD actuators handles
 #-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

  # minimum mass flow rate actuator
  #mdot_min_act = my_atc.minimumMassFlowRateActuator.get
  #mdot_min_act.setName("#{my_atc.name}_m_dot_min")
	#mdot_min_act.setActuatedComponent(my_atc)

  # maximum mass flow rate actuator
	#mdot_max_act = my_atc.maximumMassFlowRateActuator.get
	#mdot_max_act.setName("#{my_atc.name}_m_dot_max")
	#mdot_max_act.setActuatedComponent(my_atc)

  # mass flow rate actuator - flow leaving the measure
  mdot_act = OpenStudio::Model::EnergyManagementSystemActuator.new(my_atc, "Air Connection 1", "Mass Flow Rate")
  mdot_act.setName("#{my_atc.name}_m_dot_Act")
  mdot_act.setActuatedComponent(my_atc)

  # Humidity ratio
	hum_act = OpenStudio::Model::EnergyManagementSystemActuator.new(my_atc, "Air Connection 1", "Outlet Humidity Ratio")
	hum_act.setName("#{my_atc.name}_Humidity_Act")
	hum_act.setActuatedComponent(my_atc)

  # minimum loading capacity actuator
  #cap_min_act = my_atc.minimumLoadingCapacityActuator.get
	#cap_min_act.setName("#{my_atc.name}_Cap_Min_Act")
	#cap_min_act.setActuatedComponent(my_atc)

  # maximum loading capacity actuator
  #cap_max_act = my_atc.maximumLoadingCapacityActuator.get
  #cap_max_act.setName("#{my_atc.name}_Cap_Max_Act")
  #cap_max_act.setActuatedComponent(my_atc)

  # optimal loading capacity actuator
  #cap_opt_act = my_atc.optimalLoadingCapacityActuator.get
  #cap_opt_act.setName("#{my_atc.name}_Cap_Opt_Act")
	#cap_opt_act.setActuatedComponent(my_atc)

  # outlet temperature actuator
  tout_act = OpenStudio::Model::EnergyManagementSystemActuator.new(my_atc, "Air Connection 1", "Outlet Temperature")
	tout_act.setName("#{my_atc.name}_t_out_Act")
	tout_act.setActuatedComponent(my_atc)

  # high outlet temperature limit actuator
  #tout_max_act = OpenStudio::Model::EnergyManagementSystemActuator.new(my_atc, "Plant Connection 1", "High Outlet Temperature Limit")
  #tout_max_act.setName("#{my_atc.name}_Tout_Max_Act")

  # sensible heat loss
  q_loss_act = OpenStudio::Model::EnergyManagementSystemActuator.new(my_atc, "Component Zone Internal Gain", "Sensible Heat Gain Rate")
  q_loss_act.setName("#{my_atc.name}_Q_loss_Act")
  
  # Air loop volumetric flow rate actuator
  #vdot_act = OpenStudio::Model::EnergyManagementSystemActuator.new(var_fan, "Fan", "Fan Air Mass Flow Rate")
  #vdot_act.setName("#{my_atc.name}_vdot_act")
  

  #-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
	                                                                               # Get internal variables with EMS
  #-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

	 # inlet temperature internal variable
  tin_int_var = OpenStudio::Model::EnergyManagementSystemInternalVariable.new(model, 'Inlet Temperature for Air Connection 1')
  tin_int_var.setName("#{my_atc.name}_ta_in")
  tin_int_var.setInternalDataIndexKeyName("#{my_atc.name}")
  tin_int_var.setInternalDataType('Inlet Temperature for Air Connection 1')

  # inlet mass flow rate internal variable
  #mdot_int_var = OpenStudio::Model::EnergyManagementSystemInternalVariable.new(model, 'Inlet Mass Flow Rate for Plant Connection 1')
	#mdot_int_var.setName("#{my_atc.name}_m_dot_glycol")
  #mdot_int_var.setInternalDataIndexKeyName("#{my_atc.name}")
	#mdot_int_var.setInternalDataType('Inlet Mass Flow Rate for Plant Connection 1')

	# inlet specific heat internal variable
  hr_int_var = OpenStudio::Model::EnergyManagementSystemInternalVariable.new(model, 'Inlet Humidity Ratio for Air Connection 1')
  hr_int_var.setName("#{my_atc.name}_hr_Int_Var")
  hr_int_var.setInternalDataIndexKeyName("#{my_atc.name}")
  hr_int_var.setInternalDataType('Inlet Humidity Ratio for Air Connection 1')

  # inlet density internal variable
  rho_int_var = OpenStudio::Model::EnergyManagementSystemInternalVariable.new(model, 'Inlet Density for Air Connection 1')
  rho_int_var.setName("#{my_atc.name}_rho_Int_Var")
  rho_int_var.setInternalDataIndexKeyName("#{my_atc.name}")
  rho_int_var.setInternalDataType('Inlet Density for Air Connection 1')

  # specific heat of air internal variable
  cp_int_var = OpenStudio::Model::EnergyManagementSystemInternalVariable.new(model, 'Inlet Specific Heat for Air Connection 1')
  cp_int_var.setName("#{my_atc.name}_cp_Int_Var")
  cp_int_var.setInternalDataIndexKeyName("#{my_atc.name}")
  cp_int_var.setInternalDataType('Inlet Specific Heat for Air Connection 1')

  #-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
	                                                                                # Get sensor values with EMS
  #-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
	# Ambient temperature of selected zone
	space_temp_sen = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Zone Air Temperature')
	space_temp_sen.setName("#{my_atc.name}_t_amb")
	space_temp_sen.setKeyName(selected_zone)

	# Outdoor air drybulb temperature
	oa_dbt_sen = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Outdoor Air Drybulb Temperature')
	oa_dbt_sen.setName("#{my_atc.name}_t_ext")
	oa_dbt_sen.setKeyName('Environment')

	
	p_bldg_sen = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Facility Total Electricity Demand Rate')
	p_bldg_sen.setName("#{my_atc.name}_p_bat")
	p_bldg_sen.setKeyName('Whole Building')

	# charging schedule value sensor
	aut_char_sen = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
	aut_char_sen.setName("#{my_atc.name}_aut_char")
	aut_char_sen.setKeyName("#{user_selected_charging_schedule.name}")

	# discharging schedule value sensor
	aut_dischar_sen = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
	aut_dischar_sen.setName("#{my_atc.name}_aut_dischar")
	aut_dischar_sen.setKeyName("#{user_selected_discharging_schedule.name}")

	# maximum building power schedule value sensor
	p_bldg_max_sen = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
	p_bldg_max_sen.setName("#{my_atc.name}_p_max")
	p_bldg_max_sen.setKeyName("#{user_selected_pbldgmax_schedule.name}")
  
	# Target outlet air temperature schedule value sensor
	t_out_setpoint_sen = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
	t_out_setpoint_sen.setName("#{my_atc.name}_t_sup")
	t_out_setpoint_sen.setKeyName("#{user_selected_outletairtemp_schedule.name}")
  
	# Air loop mass flow rate sensor [kg/s]
	mdot_sen = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Fan Air Mass Flow Rate')
	mdot_sen.setName("#{my_atc.name}_mdot_sensor")
	mdot_sen.setKeyName("#{var_fan.name}")

  #-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
	                                                                                                   # create global variables
  #-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

	alpha_param = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_AlphaParam")
	beta_param = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_BetaParam")
	average_brick_temp = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_AverageBrickTemp")
	brick_init_temp = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_BrickInitTemp")
	brick_temp_trend = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_BrickTempTrend")
	brick_target_core_temp = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_BrickTargetCoreTemp")
	minimum_brick_temp = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_MinimumBrickTemp")
	maximum_brick_temp = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_MaximumBrickTemp")
	minimum_outdoor_temp = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_MinimumOutdoorTemp")
	maximum_outdoor_temp = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_MaximumOutdoorTemp")
	brick_setpoint_error = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_BrickSetpointError")
	brick_deadband = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_BrickTempDeadband")
	low_deadband = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_LowDeadband")
	mdot_max = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_MaxAtcMassFlowRate")
	mdot_ets = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_ETSMassFlowRate")
	ets_max_pheat = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_ETSMaxPheat")
	ets_t_in = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_ETSInletTemp")
	ets_t_out = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_ETSOutletTemp")
	airloop_temp_SP = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_AirloopAirTempSP")
	atc_nameplate_power = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_AtcNameplatePower")
	maximum_building_power = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_MaximumBuildingPower")
	available_charging_power = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_AvailableChargingPower")
	building_power_dmd = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_BuildingPowerDmd")
	atc_charging_auth = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_AtcChargingAuth")
	atc_discharging_auth = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_AtcDischargingAuth")
	p_req = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_Preq")
	p_avail = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_Pavail")
	storage_cap = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_CParam")
	ets_pheat = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_ETSPheat")
	ets_eheat = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_ETSEheat")
	ets_heat_dmd = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_ETSHeatingDemand")
	storage_electric_pwr = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model,  "#{my_atc.name}_StorageElectricPwr")
	storage_electric_ener = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_StorageElectricEner")
	ua_eff_param = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_UAeffParam")
	storage_loss_pwr= OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_StorageLossPwr")
	storage_loss_ener= OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_StorageLossEner")
	nominal_ETS_Dch = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_PheatTest")
	htf_Cp = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_Cp")
	htf_density = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_Rho")
	prevtimestependtime = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_PreviousTimeStepEndTime")
	prevtimestepbegintime = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, "#{my_atc.name}_PreviousTimeStepBeginTime")

  #-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
	                                                                                                  # create trend variables
  #-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

	# Create new EnergyManagementSystem:TrendVariable object to hold the facility electric demand history
	elec_demand_trend = OpenStudio::Model::EnergyManagementSystemTrendVariable.new(model, p_bldg_sen)
	elec_demand_trend.setName("#{my_atc.name}_pbat_trend")
	elec_demand_trend.setNumberOfTimestepsToBeLogged(144)

	# Create new EnergyManagementSystem:TrendVariable object  to hold the brick core temperature history
	brick_temp_trend = OpenStudio::Model::EnergyManagementSystemTrendVariable.new(model,average_brick_temp)
	brick_temp_trend.setName("#{my_atc.name}_t_bricks_past")
	brick_temp_trend.setNumberOfTimestepsToBeLogged(144)

	# Create new EnergyManagementSystem:TrendVariable object and configure to hold outdoor temperature
	oa_dbt_trend = OpenStudio::Model::EnergyManagementSystemTrendVariable.new(model, oa_dbt_sen)
	oa_dbt_trend.setName("#{my_atc.name}_t_ext_past")
	oa_dbt_trend.setNumberOfTimestepsToBeLogged(144)
  
  
	# Create new EnergyManagementSystem:TrendVariable object to hold the  ETS electric demand history
	elec_cons_trend = OpenStudio::Model::EnergyManagementSystemTrendVariable.new(model, storage_electric_pwr)
	elec_cons_trend.setName("#{my_atc.name}_patc_trend")
	elec_cons_trend.setNumberOfTimestepsToBeLogged(144)
  #-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
                                                                                                # Create initilization program
  #-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

	initprogram = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    initprogram.setName("#{my_atc.name}_initATCThermElectModel")
    body = <<-EMS
	SET #{atc_nameplate_power.name} = #{pelec_max}*1000
	SET #{maximum_building_power.name} = #{p_bldg_max_sen.name}
	SET #{brick_init_temp.name} = #{initial_temperature}
	SET #{maximum_brick_temp.name} = #{storage_Temperature_High_Limit}
	SET #{minimum_brick_temp.name} = #{storage_Temperature_Low_Limit}
	SET #{maximum_outdoor_temp.name} = #{maximum_Outdoor_Temperature}
	SET #{minimum_outdoor_temp.name} = #{minimum_Outdoor_Temperature}
	SET #{average_brick_temp.name} = #{brick_init_temp.name}
	SET #{brick_temp_trend.name} = #{brick_init_temp.name}
	SET #{brick_target_core_temp.name} = #{maximum_brick_temp.name}
	SET #{brick_deadband.name} = #{brick_temp_deadband}
	SET #{low_deadband.name} = #{brick_target_core_temp.name} - #{brick_deadband.name}
	SET #{brick_setpoint_error.name} = #{brick_target_core_temp.name} + #{brick_deadband.name} - #{average_brick_temp.name}
	SET #{atc_charging_auth.name} = #{aut_char_sen.name}
	SET #{atc_discharging_auth.name} = #{aut_dischar_sen.name}
	SET #{available_charging_power.name} = 0
	SET #{p_avail.name} = 0
	SET #{p_req.name} = 0
	SET #{storage_loss_pwr.name} = 0
	SET #{storage_electric_pwr.name} = 0
	SET #{htf_density.name} = #{rho_int_var.name}
	SET #{hum_act.name} = #{hr_int_var.name}
	SET #{mdot_max.name} = #{htf_density.name} * #{vol_flow_rate}
	SET #{mdot_ets.name} = @Min #{mdot_sen.name} #{mdot_max.name}
	SET #{mdot_act.name} = #{mdot_ets.name}
	SET #{storage_cap.name} = #{sto_cap}
	SET #{ua_eff_param.name} = #{ua_eff}
	SET #{alpha_param.name} = #{alpha}
	SET #{beta_param.name} = #{beta}
	SET #{nominal_ETS_Dch.name} = #{pheat_max}*1000
	SET #{htf_Cp.name} = #{cp_int_var.name}
	SET #{airloop_temp_SP.name} = #{t_out_setpoint_sen.name}
	SET #{ets_t_in.name} = #{tin_int_var.name}
	
	SET linRegressResult = ((#{alpha_param.name} * #{brick_init_temp.name} + #{beta_param.name})*#{atc_discharging_auth.name})*1000
	SET #{ets_max_pheat.name} = @Min linRegressResult #{nominal_ETS_Dch.name}
	SET #{ets_heat_dmd.name} = #{mdot_ets.name} * #{htf_Cp.name} * (#{airloop_temp_SP.name} - #{ets_t_in.name})
	SET #{ets_pheat.name} = @Min #{ets_heat_dmd.name} #{ets_max_pheat.name}
	SET Calc_Tout = 0
	IF #{mdot_ets.name} > 0
		SET Calc_Tout = (#{ets_pheat.name}/(#{mdot_ets.name} * #{htf_Cp.name})) + #{ets_t_in.name}
	ENDIF
	SET #{ets_t_out.name} = @Max #{ets_t_in.name} Calc_Tout
	SET #{tout_act.name} = #{ets_t_out.name}

    EMS
    initprogram.setBody(body)
	
	#Link the initialization program to the ETS  model
	my_atc.setInitializationSimulationProgram(initprogram)

	# initialization programs program calling mananger
	initpcm = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
  initpcm.setName("#{my_atc.name}_ThermElect_Init_Programs")
  initpcm.setCallingPoint('BeginNewEnvironment')
  initpcm.addProgram(initprogram)
  
  my_atc.setModelSetupandSizingProgramCallingManager(initpcm)
  
  #-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
	                                                                                                              # Create simulation program
  #-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
  


	simprogram = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    simprogram.setName("#{my_atc.name}_SimATCThermElectModel")
    body = <<-EMS	
	SET initial_timestamp_of_last_iteration = #{prevtimestepbegintime.name}
	SET final_timestamp_of_last_iteration =  #{prevtimestependtime.name}
	SET initial_timestamp_of_current_iteration = TimeStepNum
	SET final_timestamp_of_current_iteration = CurrentTime

	IF initial_timestamp_of_current_iteration == initial_timestamp_of_last_iteration
		SET reiteration_flag = 1
	ELSE
		SET reiteration_flag = 0
		SET #{brick_init_temp.name} = #{average_brick_temp.name}
	ENDIF

	SET #{prevtimestependtime.name} = CurrentTime
	SET #{prevtimestepbegintime.name} = TimeStepNum
	
	SET pfacility = #{p_bldg_sen.name}
	SET patc = #{storage_electric_pwr.name}
	
	SET #{building_power_dmd.name} = pfacility - patc
	
	SET #{maximum_building_power.name} = #{p_bldg_max_sen.name}
	SET #{available_charging_power.name} = #{maximum_building_power.name} - #{building_power_dmd.name}
	SET #{p_avail.name} = @Min #{available_charging_power.name} #{atc_nameplate_power.name}
	SET #{p_avail.name} = @Max 0 #{p_avail.name}
	
	SET timestep_8_hours = 8/ZoneTimeStep
    SET text = @TrendMin #{oa_dbt_trend.name} timestep_8_hours

	IF text < #{minimum_outdoor_temp.name}
	   SET #{brick_target_core_temp.name} = #{maximum_brick_temp.name}
	ELSEIF text > #{maximum_outdoor_temp.name}
	   SET #{brick_target_core_temp.name} = #{minimum_brick_temp.name}
	ELSE
	   SET #{brick_target_core_temp.name} = #{maximum_brick_temp.name}+(text-#{minimum_outdoor_temp.name})*((#{minimum_brick_temp.name}-#{maximum_brick_temp.name})/(#{maximum_outdoor_temp.name}-#{minimum_outdoor_temp.name}))
	ENDIF
	
	SET #{low_deadband.name} = #{brick_target_core_temp.name} - #{brick_deadband.name}
	IF #{low_deadband.name} > #{brick_init_temp.name}
		SET #{brick_setpoint_error.name} = #{brick_target_core_temp.name} + #{brick_deadband.name} - #{brick_init_temp.name}
	ELSEIF #{storage_electric_pwr.name} > #{storage_loss_pwr.name}
		SET #{brick_setpoint_error.name} = #{brick_target_core_temp.name} + #{brick_deadband.name} - #{brick_init_temp.name}
	ELSE
		SET #{brick_setpoint_error.name} = #{brick_target_core_temp.name} - #{brick_deadband.name} - #{brick_init_temp.name}
	ENDIF
	
	SET #{p_req.name} = #{brick_setpoint_error.name} * #{storage_cap.name} * 1000 / (SystemTimeStep*3600)
	SET #{p_req.name} = @Max 0 #{p_req.name}
	SET Pcharge = @Min #{p_req.name} #{p_avail.name}
    SET #{atc_charging_auth.name} = #{aut_char_sen.name}
	SET #{storage_electric_pwr.name} = #{atc_charging_auth.name} * Pcharge
	SET #{storage_electric_ener.name} = #{storage_electric_pwr.name} * SystemTimeStep * 3600
    
	SET #{atc_discharging_auth.name} = #{aut_dischar_sen.name}
    SET Tliminf = 93
    IF #{brick_init_temp.name} <= Tliminf
      SET #{atc_discharging_auth.name} = 0
    ENDIF
	
    SET #{htf_density.name} = #{rho_int_var.name}
    SET #{hum_act.name} = #{hr_int_var.name}
	SET #{mdot_ets.name} = @Min #{mdot_sen.name} #{mdot_max.name}
	SET #{mdot_act.name} = #{mdot_ets.name}
	SET #{htf_Cp.name} = #{cp_int_var.name}
	SET #{airloop_temp_SP.name} = #{t_out_setpoint_sen.name}
	SET #{ets_t_in.name} = #{tin_int_var.name}
	
	SET linRegressResult = ((#{alpha_param.name} * #{brick_init_temp.name} + #{beta_param.name}))*1000
	SET #{ets_max_pheat.name} = @Min linRegressResult #{nominal_ETS_Dch.name}
	SET #{ets_heat_dmd.name} = #{mdot_ets.name} * #{htf_Cp.name} * (#{airloop_temp_SP.name} - #{ets_t_in.name}) * #{atc_discharging_auth.name}
	SET #{ets_pheat.name} = @Min #{ets_heat_dmd.name} #{ets_max_pheat.name}
	SET #{ets_eheat.name} = #{ets_pheat.name} * SystemTimeStep * 3600
	SET Calc_Tout = 0
	IF #{mdot_ets.name} > 0
		SET Calc_Tout = (#{ets_pheat.name}/(#{mdot_ets.name} * #{htf_Cp.name})) + #{ets_t_in.name}
	ENDIF
	SET #{ets_t_out.name} = @Max #{ets_t_in.name} Calc_Tout
	SET #{tout_act.name} = #{ets_t_out.name}

	SET #{storage_loss_pwr.name} = #{ua_eff_param.name} * (#{brick_init_temp.name} - #{space_temp_sen.name})
	SET #{q_loss_act.name} = #{storage_loss_pwr.name}
	SET #{storage_loss_ener.name} = #{storage_loss_pwr.name} * SystemTimeStep * 3600

	IF WarmupFlag == 1
		SET #{storage_electric_pwr.name} = (#{ets_pheat.name}+#{storage_loss_pwr.name})
	ENDIF

	SET #{average_brick_temp.name} = #{brick_init_temp.name} + (SystemTimeStep * 3600/#{storage_cap.name}) * (#{storage_electric_pwr.name} - #{ets_pheat.name} - #{storage_loss_pwr.name})/1000
  EMS
  simprogram.setBody(body)
  # set program calling managers and programs
  simpcm = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
  simpcm.setName("#{my_atc.name}_ThermElect_Sim_Programs")
  simpcm.setCallingPoint('UserDefinedComponentModel')
  simpcm.addProgram(simprogram)
  
  
  #Link the simulation program calling manager to the ETS model
  my_atc.setOverallModelSimulationProgramCallingManager(simpcm)
  #Link the simulation program to the ETs Model
  my_atc.setOverallSimulationProgram(simprogram)
	

  # EMS output
  output_ems = model.getOutputEnergyManagementSystem
  output_ems.setEMSRuntimeLanguageDebugOutputLevel("None")
  #output_ems.setEMSRuntimeLanguageDebugOutputLevel("Verbose")

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
                                                                                                  # CUSTOM OUTPUT VARIABLES
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

  # Average brick temperature (current)
  eout_average_brick_temp = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, average_brick_temp)
  eout_average_brick_temp.setName("#{my_atc.name}_Brick_End_Temperature(t+1)")
  eout_average_brick_temp.setEMSVariableName("#{average_brick_temp.name}")
  eout_average_brick_temp.setUnits("C")
  eout_average_brick_temp.setTypeOfDataInVariable("Averaged")
  eout_average_brick_temp.setUpdateFrequency("SystemTimeStep")
  v = OpenStudio::Model::OutputVariable.new("#{eout_average_brick_temp.name}", model)
  v.setName("#{eout_average_brick_temp.name}")
  v.setReportingFrequency(report_freq)

  # maximum heating capacity
  eout_ets_max_pheat = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, ets_max_pheat)
  eout_ets_max_pheat.setName("#{my_atc.name}_Pheat_max")
  eout_ets_max_pheat.setEMSVariableName("#{ets_max_pheat.name}")
  eout_ets_max_pheat.setUnits("W")
  eout_ets_max_pheat.setTypeOfDataInVariable("Averaged")
  eout_ets_max_pheat.setUpdateFrequency("SystemTimeStep")
  v = OpenStudio::Model::OutputVariable.new("#{eout_ets_max_pheat.name}", model)
  v.setName("#{eout_ets_max_pheat.name}")
  v.setReportingFrequency(report_freq)

  # Target brick temperature
  eout_target_brick_temp = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, brick_target_core_temp)
  eout_target_brick_temp.setName("#{my_atc.name}_Brick_Target_Core_Temperature")
  eout_target_brick_temp.setEMSVariableName("#{brick_target_core_temp.name}")
  eout_target_brick_temp.setUnits("C")
  eout_target_brick_temp.setTypeOfDataInVariable("Averaged")
  eout_target_brick_temp.setUpdateFrequency("SystemTimeStep")
  v = OpenStudio::Model::OutputVariable.new("#{eout_target_brick_temp.name}", model)
  v.setName("#{eout_target_brick_temp.name}")
  v.setReportingFrequency(report_freq)

  # Brick temp at beginning of  timestep
  eout_initial_brick_temp = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, brick_init_temp)
  eout_initial_brick_temp.setName("#{my_atc.name}_Brick_Initial_Temperature(t)")
  eout_initial_brick_temp.setEMSVariableName("#{brick_init_temp.name}")
  eout_initial_brick_temp.setUnits("C")
  eout_initial_brick_temp.setTypeOfDataInVariable("Averaged")
  eout_initial_brick_temp.setUpdateFrequency("SystemTimeStep")
  v = OpenStudio::Model::OutputVariable.new("#{eout_initial_brick_temp.name}", model)
  v.setName("#{eout_initial_brick_temp.name}")
  v.setReportingFrequency(report_freq)

 # Mass flow rate requested by airloop
  eout_airloop_mass_flow_rate = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, mdot_act)
  eout_airloop_mass_flow_rate.setName("#{my_atc.name}_Airloop_Mass_Flow_Rate")
  eout_airloop_mass_flow_rate.setEMSVariableName("#{mdot_act.name}")
  eout_airloop_mass_flow_rate.setUnits("kg/s")
  eout_airloop_mass_flow_rate.setTypeOfDataInVariable("Averaged")
  eout_airloop_mass_flow_rate.setUpdateFrequency("SystemTimeStep")
  v = OpenStudio::Model::OutputVariable.new("#{eout_airloop_mass_flow_rate.name}", model)
  v.setName("#{eout_airloop_mass_flow_rate.name}")
  v.setReportingFrequency(report_freq)

  # Electric power used by ATC
  eout_storage_electric_pwr = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, storage_electric_pwr)
  eout_storage_electric_pwr.setName("#{my_atc.name}_Electric_Power")
  eout_storage_electric_pwr.setEMSVariableName("#{storage_electric_pwr.name}")
  eout_storage_electric_pwr.setUnits("W")
  eout_storage_electric_pwr.setTypeOfDataInVariable("Averaged")
  eout_storage_electric_pwr.setUpdateFrequency("SystemTimeStep")
  v = OpenStudio::Model::OutputVariable.new("#{eout_storage_electric_pwr.name}", model)
  v.setName("#{eout_storage_electric_pwr.name}")
  v.setReportingFrequency(report_freq)

  # Maximum Allowed Building Electric Power
  eout_maximum_building_power = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, maximum_building_power)
  eout_maximum_building_power.setName("#{my_atc.name}_Maximum_Allowed_Building_Peak_Power")
  eout_maximum_building_power.setEMSVariableName("#{maximum_building_power.name}")
  eout_maximum_building_power.setUnits("W")
  eout_maximum_building_power.setTypeOfDataInVariable("Averaged")
  eout_maximum_building_power.setUpdateFrequency("SystemTimeStep")
  v = OpenStudio::Model::OutputVariable.new("#{eout_maximum_building_power.name}", model)
  v.setName("#{eout_maximum_building_power.name}")
  v.setReportingFrequency(report_freq)

# current dmd 
 # Current dmd 
  eout_curr_building_power= OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, building_power_dmd)
  eout_curr_building_power.setName("#{my_atc.name}_Building_Elec_Demand")
  eout_curr_building_power.setEMSVariableName("#{building_power_dmd.name}")
  eout_curr_building_power.setUnits("W")
  eout_curr_building_power.setTypeOfDataInVariable("Averaged")
  eout_curr_building_power.setUpdateFrequency("SystemTimeStep")
  v = OpenStudio::Model::OutputVariable.new("#{eout_curr_building_power.name}", model)
  v.setName("#{eout_curr_building_power.name}")
  v.setReportingFrequency(report_freq)


  # Available charging power
  eout_available_charging_power = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, available_charging_power)
  eout_available_charging_power.setName("#{my_atc.name}_Available_Charging_Power_for_ATC")
  eout_available_charging_power.setEMSVariableName("#{available_charging_power.name}")
  eout_available_charging_power.setUnits("W")
  eout_available_charging_power.setTypeOfDataInVariable("Averaged")
  eout_available_charging_power.setUpdateFrequency("SystemTimeStep")
  v = OpenStudio::Model::OutputVariable.new("#{eout_available_charging_power.name}", model)
  v.setName("#{eout_available_charging_power.name}")
  v.setReportingFrequency(report_freq)


  # Charging authorization (schedule value)
  eout_atc_charging_auth = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, atc_charging_auth)
  eout_atc_charging_auth.setName("#{my_atc.name}_Scheduled_Charging_Authorization")
  eout_atc_charging_auth.setEMSVariableName("#{atc_charging_auth.name}")
  #eout_atc_charging_auth.setUnits("")
  eout_atc_charging_auth.setTypeOfDataInVariable("Averaged")
  eout_atc_charging_auth.setUpdateFrequency("SystemTimeStep")
  v = OpenStudio::Model::OutputVariable.new("#{eout_atc_charging_auth.name}", model)
  v.setName("#{eout_atc_charging_auth.name}")
  v.setReportingFrequency(report_freq)

  # Discharging authorization (schedule value)
  eout_atc_discharging_auth = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, atc_discharging_auth)
  eout_atc_discharging_auth.setName("#{my_atc.name}_Scheduled_Discharging_Authorization")
  eout_atc_discharging_auth.setEMSVariableName("#{atc_discharging_auth.name}")
  #eout_atc_charging_auth.setUnits("")
  eout_atc_discharging_auth.setTypeOfDataInVariable("Averaged")
  eout_atc_discharging_auth.setUpdateFrequency("SystemTimeStep")
  v = OpenStudio::Model::OutputVariable.new("#{eout_atc_discharging_auth.name}", model)
  v.setName("#{eout_atc_discharging_auth.name}")
  v.setReportingFrequency(report_freq)

  # Metered Electric energy
  eout_storage_electric_ener  = OpenStudio::Model::EnergyManagementSystemMeteredOutputVariable.new(model, storage_electric_ener )
  eout_storage_electric_ener.setName("#{my_atc.name}_Electric_Energy")
  eout_storage_electric_ener.setEMSVariableName("#{storage_electric_ener.name}")
  eout_storage_electric_ener.setUnits("J")
  # eout_storage_electric_ener.setTypeOfDataInVariable("Summed")
  eout_storage_electric_ener.setUpdateFrequency("SystemTimeStep")
  eout_storage_electric_ener.setResourceType("Electricity")
  eout_storage_electric_ener.setGroupType("Plant")
  eout_storage_electric_ener.setEndUseCategory("Heating")
  v = OpenStudio::Model::OutputVariable.new("#{eout_storage_electric_ener.name}", model)
  v.setName("#{eout_storage_electric_ener.name}")
  v.setReportingFrequency(report_freq)

  # Thermal power delivered by ATC
  eout_ets_pheat = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, ets_pheat)
  eout_ets_pheat.setName("#{my_atc.name}_ETS_Thermal_Output")
  eout_ets_pheat.setEMSVariableName("#{ets_pheat.name}")
  eout_ets_pheat.setUnits("W")
  eout_ets_pheat.setTypeOfDataInVariable("Averaged")
  eout_ets_pheat.setUpdateFrequency("SystemTimeStep")
  v = OpenStudio::Model::OutputVariable.new("#{eout_ets_pheat.name}", model)
  v.setName("#{eout_ets_pheat.name}")
  v.setReportingFrequency(report_freq)
  
  eout_ets_heat_dmd = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, ets_heat_dmd)
  eout_ets_heat_dmd.setName("#{my_atc.name}_ETS_Heating_Demand")
  eout_ets_heat_dmd.setEMSVariableName("#{ets_heat_dmd.name}")
  eout_ets_heat_dmd.setUnits("W")
  eout_ets_heat_dmd.setTypeOfDataInVariable("Averaged")
  eout_ets_heat_dmd.setUpdateFrequency("SystemTimeStep")
  v = OpenStudio::Model::OutputVariable.new("#{ets_heat_dmd.name}", model)
  v.setName("#{ets_heat_dmd.name}")
  v.setReportingFrequency(report_freq)

  #heating_power_dmd / load request for ETS
  #eout_load_req_ets = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, load_req_ets)
  #eout_load_req_ets.setName("#{my_atc.name}_RequestedLoad")
  #eout_load_req_ets.setEMSVariableName("#{load_req_ets.name}")
  #eout_load_req_ets.setUnits("W")
  #eout_load_req_ets.setTypeOfDataInVariable("Averaged")
  #eout_load_req_ets.setUpdateFrequency("SystemTimeStep")
  #v = OpenStudio::Model::OutputVariable.new("#{load_req_ets.name}", model)
  #v.setName("#{load_req_ets.name}")
  #v.setReportingFrequency(report_freq)

  # Thermal Energy delivered by ATC
  eout_ets_eheat = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, ets_eheat)
  eout_ets_eheat.setName("#{my_atc.name}_ETS_Thermal_Energy")
  eout_ets_eheat.setEMSVariableName("#{ets_eheat.name}")
  eout_ets_eheat.setUnits("J")
  eout_ets_eheat.setTypeOfDataInVariable("Summed")
  eout_ets_eheat.setUpdateFrequency("SystemTimeStep")
  v = OpenStudio::Model::OutputVariable.new("#{eout_ets_eheat.name}", model)
  v.setName("#{eout_ets_eheat.name}")
  v.setReportingFrequency(report_freq)


  # ATC power loss
  eout_storage_loss_pwr = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, storage_loss_pwr)
  eout_storage_loss_pwr.setName("#{my_atc.name}_Thermal_Power_Loss")
  eout_storage_loss_pwr.setEMSVariableName("#{storage_loss_pwr.name}")
  eout_storage_loss_pwr.setUnits("W")
  eout_storage_loss_pwr.setTypeOfDataInVariable("Averaged")
  eout_storage_loss_pwr.setUpdateFrequency("SystemTimeStep")
  v = OpenStudio::Model::OutputVariable.new("#{eout_storage_loss_pwr.name}", model)
  v.setName("#{eout_storage_loss_pwr.name}")
  v.setReportingFrequency(report_freq)

 # ATC energy loss
  eout_storage_loss_ener = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, storage_loss_ener)
  eout_storage_loss_ener.setName("#{my_atc.name}_Thermal_Energy_Loss")
  eout_storage_loss_ener.setEMSVariableName("#{storage_loss_ener.name}")
  eout_storage_loss_ener.setUnits("J")
  eout_storage_loss_ener.setTypeOfDataInVariable("Summed")
  eout_storage_loss_ener.setUpdateFrequency("SystemTimeStep")
  v = OpenStudio::Model::OutputVariable.new("#{eout_storage_loss_ener.name}", model)
  v.setName("#{eout_storage_loss_ener.name}")
  v.setReportingFrequency(report_freq)
  
 # ETS outlet temperature
  eout_ets_t_out = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, ets_t_out)
  eout_ets_t_out.setName("#{my_atc.name}_ETS_Outlet_Temp")
  eout_ets_t_out.setEMSVariableName("#{ets_t_out.name}")
  eout_ets_t_out.setUnits("C")
  eout_ets_t_out.setTypeOfDataInVariable("Averaged")
  eout_ets_t_out.setUpdateFrequency("SystemTimeStep")
  v = OpenStudio::Model::OutputVariable.new("#{eout_ets_t_out.name}", model)
  v.setName("#{eout_ets_t_out.name}")
  v.setReportingFrequency(report_freq)
  
 # ETS mass flow rate   
  eout_mdot_ets = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, mdot_ets)
  eout_mdot_ets.setName("#{my_atc.name}_ETS_Flow_Rate")
  eout_mdot_ets.setEMSVariableName("#{mdot_ets.name}")
  eout_mdot_ets.setUnits("kg/s")
  eout_mdot_ets.setTypeOfDataInVariable("Averaged")
  eout_mdot_ets.setUpdateFrequency("SystemTimeStep")
  v = OpenStudio::Model::OutputVariable.new("#{eout_mdot_ets.name}", model)
  v.setName("#{eout_mdot_ets.name}")
  v.setReportingFrequency(report_freq)
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#
                                                                              # PLANT EQUIPMENT OPERATION SCHEMES
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------#

	# # retrieve all electric thermal storage devices in the model # these could be identified from their unique type :PlantComponentUserDefined and a prefix "SimETS"
	# pcudobjects = model.getPlantComponentUserDefineds
	# electric_thermal_storage_equipment_list = []

	# if !pcudobjects.empty?
		# pcudobjects.each do |object|
		# parts = object.name.to_s.split(/_/, 2)
		# identifier = parts[0]
		# if identifier == "SimETS"
			# electric_thermal_storage_equipment_list.push(object)
		# end
		# end

	# end

	# highest_priority_equipment =[] # these refer to electric boilers
	# lowest_priority_equipment=[]   # these refer to fossil fuel fired boilers

	# if !boilers.empty?
		# boilers.each do |b|
			# if  b.fuelType() == 'Electricity'
				# highest_priority_equipment.push(b)
			# else
				# lowest_priority_equipment.push(b)
			# end
		# end
	# end


  # htg_op_scheme = OpenStudio::Model::PlantEquipmentOperationHeatingLoad.new(model)

	# # Add highest priority equipment first
	# highest_priority_equipment.each do |equip|
	# htg_op_scheme.addEquipment(1000000000, equip)
	# end

	# # Add ETS devices
	# electric_thermal_storage_equipment_list.each do |equip|
	# htg_op_scheme.addEquipment(1000000000, equip)
	# end

	# # Add lowest priority equipment last
	# lowest_priority_equipment.each do |equip|
	# htg_op_scheme.addEquipment(1000000000, equip)
	# end

  # user_selected_loop.setPlantEquipmentOperationHeatingLoad(htg_op_scheme)

    return true
  end # end the run method

end # end the measure

AddForcedAirCentralElectricThermalStorage.new.registerWithApplication


