# Este codigo simplemente es un script que debe ajuntarse a un nodo WorldEnvironment
# para que la calidad del environment se ajuste a la memoria VRAM disponible
extends WorldEnvironment

# Debe contener el nombre de una variable booleana de GameInstance inicialmente puesta a false para que únicamente este proceso se cargue una única evz preferiblemente en el proceso de carga del juego
@export var controlVar: String = ""

# Función que nos proporciona la cantidad de memoria VRAM disponible a través de una llamada al SO
func get_vram_real_mb() -> float :
	
	var os_name = OS.get_name()
	var output = []

	if os_name == "Windows" :
		# Execute a quick native command to extract the exact dedicated memory of the active GPU
		OS.execute("powershell", ["-Command", "(Get-CimInstance Win32_VideoController | Select-Object -First 1).AdapterRAM"], output)
		if output.size() > 0 and str(output[0]).strip_edges().is_valid_int():
			var bytes = str(output[0]).strip_edges().to_int()
			return bytes / 1024.0 / 1024.0

	elif os_name == "Linux":
		# Try reading native Nvidia systems
		OS.execute("nvidia-smi", ["--query-gpu=memory.total", "--format=csv,noheader,nounits"], output)
		if output.size() > 0 and str(output[0]).strip_edges().is_valid_int():
			return str(output[0]).strip_edges().to_int()
	
	# Returns 512 for safety in case the amount of available VRAM cannot be determined
	return 512

func _init() -> void:
	pass

func _ready() -> void :

	if controlVar == "" : return

	# Si la variable es true no se lleva a cabo el proceso
	if not GameInstance.get(controlVar) : GameInstance.set(controlVar, true)
	else : return

	if not environment : return

	var vram_gb : float = get_vram_real_mb()
	var device_type : int = RenderingServer.get_video_adapter_type()

	# 1. GODOT 4.7+ FUTURE: DOES IT SUPPORT HARDWARE RAY TRACING?
	# We use 'has_method' for safety so that it doesn't cause an error in your current build 4.6
	if RenderingServer.has_method("is_ray_tracing_supported") and RenderingServer.call("is_ray_tracing_supported") :
		environment.sdfgi_enabled = false 
		# Here you would activate the RT Hardware options of 4.7, not yet done
		MyLogger.info("[Render] 4.7+ Detectado: Usando Ray Tracing por Hardware. SDFGI: OFF", 'world_environment.gd',38,true)
		return

	# 2. LOGIC FOR GODOT 4.6 (SDFGI BY SOFTWARE)
	
	# A. INTEGRATED FILTER/CRITICAL VRAM
	if device_type == RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU and vram_gb <= 2048.0 or not device_type :
		environment.sdfgi_enabled = false
		MyLogger.info("[Render] Integrada o VRAM baja. SDFGI: OFF " + str(vram_gb) + " - " + str(device_type), 'world_environment.gd',46,true)
		return

	# B. VRAM LEVEL CONFIGURATION
	if (device_type != RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU and vram_gb <= 4608.0) or (device_type == RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU and vram_gb > 2048.0) :
		#RTX 3050 Laptop/GTX 1650 (4GB)
		environment.sdfgi_enabled = true
		environment.sdfgi_cascades = 4
		environment.sdfgi_use_occlusion = false
		environment.sdfgi_y_scale = Environment.SDFGI_Y_SCALE_75_PERCENT
		MyLogger.info("[Render] SDFGI Optimizado (VRAM <= 4GB) " + str(vram_gb) + " - " + str(device_type), 'world_environment.gd',56,true)

	elif device_type != RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU and vram_gb <= 8704.0:
		# RTX 4060 / RX 6600 (8GB) – Balance
		environment.sdfgi_enabled = true
		environment.sdfgi_cascades = 4
		environment.sdfgi_use_occlusion = true 
		environment.sdfgi_y_scale = Environment.SDFGI_Y_SCALE_100_PERCENT
		MyLogger.info("[Render] SDFGI Medio (VRAM 6GB-8GB) " + str(vram_gb) + " - " + str(device_type), 'world_environment.gd',56,true)

	else:
		# GTX 1080 Ti / RTX 3060 12GB / RTX 4070+ (10GB+)
		environment.sdfgi_enabled = true
		environment.sdfgi_cascades = 6
		environment.sdfgi_use_occlusion = true
		MyLogger.info("[Render] SDFGI Full (VRAM > 8GB) " + str(vram_gb) + " - " + str(device_type), 'world_environment.gd',71,true)
