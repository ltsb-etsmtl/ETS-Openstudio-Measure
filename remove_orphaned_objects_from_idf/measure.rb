# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class RemoveOrphanedObjectsFromIDF < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Remove orphaned objects from IDF'
  end

  # human readable description
  def description
    return 'This measure removes any remaining orphan objects from the IDF. This measure should be set as an always run measure before simulation can continue in order to avoid simulation crashes / Fatal errors.'
  end

  # human readable description of modeling approach
  def modeler_description
    return ''
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

   # no user arguments

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)  # Do **NOT** remove this line

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    objects = model.getModelObjects
    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getModelObjects.size} objects.")


    # # This fixes the issue of EMS objects orphaned after deletion of a PCUD object added by this measure
  	# # find any existing EMS:Programs or ProgramCallingManagers in the IDF file whose names begin with PCUD_InitProgram or PCUD_simProgram or PCUD_InitProgramCallingManager or PCUD_SimProgramCallingManager and Remove them
  	pcud_initProgram_found = false
  	model.getObjectsByName("PCUD_InitProgram",false).each do |object|
  	pcud_initProgram_found = true
  	object.remove
  	runner.registerInfo("a PCUD_InitProgram was deleted from the model")
  	end

  	pcud_simProgram_found = false
  	model.getObjectsByName("PCUD_SimProgram",false).each do |object|
  	pcud_simProgram_found = true
  	object.remove
  	runner.registerInfo("a PCUD_SimProgram was deleted from the model")
  	end

  	pcud_initCallingManager_found = false
  	model.getObjectsByName("PCUD_InitProgramCallingManager",false).each do |object|
  	pcud_initCallingManager_found = true
  	object.remove
  	runner.registerInfo("a PCUD_InitProgramCallingManager was deleted from the model")
  	end

  	pcud_simCallingManager_found = false
  	model.getObjectsByName("PCUD_SimProgramCallingManager",false).each do |object|
  	pcud_simCallingManager_found = true
  	object.remove
  	runner.registerInfo("a PCUD_SimProgramCallingManager was deleted from the model")
  	end


  	# find all pcud objects
  	pcudobjects = model.getObjectsByType("OS:PlantComponent:UserDefined".to_IddObjectType)
  	pcudobjectnames = []
  	pcudobjects.each do |object|
  	pcudobjectnames << object.name.to_s
  	end
  	# pcudobjectnames.each do |name|
  		# runner.registerInfo("device #{name} is in the model")
  	# end

  	counter = pcudobjects.size
  	runner.registerInfo("there are #{counter} ETS devices currently in the model: #{pcudobjectnames.inspect}")



  	# runner.registerInfo("there are #{counter} Electric Storage Devices (ETS) in the model")
  	# pcudobjectnames.each do |object|
  		# runner.registerInfo("an ETS device with the name: #{object} was found in the model" )
  	# end

  	# Find all orphaned objects : EMS:GlobalVariables, EMS:sensors, EMS:actuators, EMS:InternalVariables, EMS:outputvariable, EMS:MeteredOutputVariables EMS:TrendVariables
  	# Find all orphan EMS variables / all EMS objects are defined such that they start with the name of the pcud object ATC_....
  	ems_globalvariable = model.getObjectsByType("OS:EnergyManagementSystem:GlobalVariable".to_IddObjectType)
  	ems_sensors = model.getObjectsByType("OS:EnergyManagementSystem:Sensor".to_IddObjectType)
  	ems_actuators = model.getObjectsByType("OS:EnergyManagementSystem:Actuator".to_IddObjectType)
  	ems_internalvariables = model.getObjectsByType("OS:EnergyManagementSystem:InternalVariable".to_IddObjectType)
  	ems_outputvariables = model.getObjectsByType("OS:EnergyManagementSystem:OutputVariable".to_IddObjectType)
  	ems_meteredoutputvariables = model.getObjectsByType("OS:EnergyManagementSystem:MeteredOutputVariable".to_IddObjectType)
  	ems_trendvariables = model.getObjectsByType("OS:EnergyManagementSystem:TrendVariable".to_IddObjectType)

  		list_of_all_ems_variables = ems_globalvariable + ems_sensors + ems_actuators + ems_internalvariables + ems_outputvariables + ems_meteredoutputvariables + ems_trendvariables 
	list_of_all_ems_variables.each do |var| 
		#runner.registerInfo("a global variable with the name: #{gv.name} was found in the model") 
		parts = var.name.to_s.split(/_/, 3)
		pcudobjectUID = "#{parts[0]}_#{parts[1]}"
		# pcudobjectname = var.name.to_s.split("_").first
		#runner.registerInfo("#{pcudobjectname}") 
		if  !pcudobjectnames.include?(pcudobjectUID)
			orphan_object_flag = 1 
			runner.registerInfo("orphan object flag : #{orphan_object_flag}")
			var.remove
			runner.registerInfo("an orphan EMS object called: '#{var.name}' was removed from the model")
		else 
			orphan_object_flag = 0 
			runner.registerInfo("orphan object flag : #{orphan_object_flag}")
			next 
			
			
		end 
	end 


    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getModelObjects.size} objects.")

    return true
    # Return the model with the orphaned objects removed
   return model
  end
end

# register the measure to be used by the application
RemoveOrphanedObjectsFromIDF.new.registerWithApplication
