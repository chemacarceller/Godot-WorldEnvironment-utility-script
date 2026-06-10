# Dentro de GameInstance.gd (Tu Autoload)

# Estructura de datos unificada para el Hardware y Estado de Video
var gpu_data : Dictionary = {
	"vp_detectada": false,      # Controla si el Viewport/Hardware ya fue procesado
	"vram_gb": 512.0 / 1024.0,   # Valor por defecto seguro en Gigabytes
	"device_type": 0             # Tipo de dispositivo (Dedicada, Integrada, etc.)
}

# Variables individuales de control para cada uno de tus escenarios
var env_menu_configurado : bool = false
var env_nivel1_configurado : bool = false
var env_nivel2_configurado : bool = false
