# Godot-WorldEnvironment-utility-script

This script must be associated with the WorldEnvironment node of each scene in the game. It performs a process of checking the VRAM and graphics card type, and based on this data, configures a series of parameters for both the ViewPort and the environment attribute, adjusting them to four profiles: LOW, MEDIUM, HIGH, and ULTRA.

The ViewPort configuration is only performed once, in the first scene that is loaded. In subsequent scenes, this check is omitted as it is no longer necessary. A structure must be created in the GameInstance to store the VRAM, the graphics card type, and whether the ViewPort configuration has already been applied (initially set to false).

The Environment configuration is only checked once for each scene, managed through a configurable flag within the GameInstance, provided it is defined in the script (the variable name) and declared in the GameInstance (with false as the default value).

Keep in mind that if you exit a scene and re-enter it, it will have been... When the scene is unloaded from memory, the scene's flag will be set to true in GameInstance, so the Environment configuration will be lost unless the WorldEnvironment node (or the entire scene) has been persistently stored in memory (see my Basic Loading Screen utility to keep things loaded in memory while the game runs from a preload screen). Since the flag is set to true, the environment configuration process will not be repeated because it was already checked the first time the scene was accessed, and this is reflected in the flag.

(If we have a set of scenes and we continuously switch between them, one solution would be to load the Environment node of each scene into memory and run the configuration script the first time we enter the scene.)

Another option would be to NOT specify a control flag in the script. In this case, the configuration will always be applied every time the WorldEnvironment node is loaded, and it would no longer be necessary to persistently load the WorldEnvironment node into memory. However, remember that this will cause a delay when loading the scene each time, so it will be necessary to indicate this in some way to improve the user experience.

The script is also designed so that if we have defined a flag in the script, but it is not declared in GameInstance, no process related to the environment will be applied.

The ViewPort configuration will always be carried out in the first WorldEnvironment node where we have added the script, and then it will not be executed again, maintaining the configuration while the game is running.

This entire process takes place in the script word_environment.gd, which uses the static class ConfigRender defined in the script ConfigRender.gd.

As mentioned, the script ConfigRender.gd declares a static class that provides a general method for setting the desired graphics profile level, which can be configured from LOW, MEDIUM, HIGH, and ULTRA. In addition to the graphics profile, you must also specify the ViewPort and the Environment to which you want to apply the configuration. This allows you to override the graphics profile assigned based on VRAM (for example, to improve performance).

This enables you to dynamically change the rendering environment settings from anywhere in the game. In other words, instead of setting the environment configuration based on VRAM, the user can choose the graphics profile they want to use.

There are many ways to implement this feature within your game.


=======================================================================================================


Este script se debe asociar obligatoriamente al nodo WorldEnvironment de cada una de las escena que tengamos en el videojuego y lleva a cabo un proceso de chequear la VRAM y el tipo de tarjeta gráfica y en función de estos datos configura una serie de parametros tanto del ViewPort como del atributo environment ajustando a cuatro perfiles LOW, MEDIUM, HIGH, ULTRA

Los configuración del ViewPort únicamente se lleva a cabo una única vez en la primera escena que se cargue, en las sucesivas escenas se omite esta comprobación ya que no sería ya necesaria, se debe crear obligatoriamente en GameInstance una estructura que almacena la VRAM, el tipo de tarjeta y si ya se ha aplicado la configuración del ViewPort inicialmente a false

la configuración del Environment únicamente se comprueba una vez para cada una de las escenas gestionado a través de un flag configurable dentro del GameInstance siempre que esté definido en el script (el nombre de la variable) y dicha variable declarada en el GameInstance (con false como valor por defecto)

Hay que tener en cuenta que si salimos de una escena y volvemos a entrar ésta habrá sido descargada de memoria, el flag de la escena estará a true en GameInstance por lo que se perderá la configuración del Environment realizada siempre que el nodo WorlEnvironment (o toda la escena en su defecto) no haya sido almacenda en memoria de forma persistente ( mirar mi utilidad Basic Loading Screen para poder dejar cosas cargadas en memoria mientras se ejecute el juego desde una pantalla de precarga), al estar el flag a true no se llevaría a cabo de nuevo el proceso de configuracion del entorno porque ya se comprobó la primera vez que se entró en él y así ha quedado reflejado con el flag

(Si tenemos un conjunto de escenas y vamos pasando de una a otra contiunamente la solución uno sería cargar el nodo Environment de cada una de las escenas en memoria y ejecutar el script de configuración la primera vez que entramos en la escena)

Otra opción sería NO especificar una flag de control en el script en cuyo caso siempre se aplicará la configuración cada vez que se cargue el nodo WorlEnvironment, y ya no sería necesario cargar el nodo WorlEnvironment en memoria de forma persistente, pero recuerda que esto provocará un retardo al cargar la escena cada vez por lo que será preciso indicarlo de alguna forma para mejorar la esperiencia de usuario

El script está diseñado también para que si hemos definido un flag en el script, pero éste no se encuentra declarado en GameInstance no se aplicará proceso alguno referente al environment

La configuración de ViewPort siempre se llevará a cabo en el primer nodo WorldEnvironment en el que tengamos añadido el script y luego ya no se volverá a ejecutar más manteniendo la configuración mientras el juego esté en marcha.

Todo este proceso se lleva a cabo en el script word_environment.gd que utiliza la clase estática ConfigRender definida en el script  ConfigRender.gd

Lo dicho,  el script ConfigRender.gd declara una clase estática que proporciona un método general para establecer el nivel de perfil gráfico que queremos configurar elegible entre LOW, MEDIUM, HIGH y ULTRA, además del perfil gráfico, hay que pasarle el ViewPort y en Environment al que queramos aplicar la configuración, de forma que podemos sobreescribir el perfil gráfico asignado en función de la VRAM (por ejemplo para que corra más holgado)

Esto permite que desde cualquier parte del juego se pueda cambiar la configuración del entorno de renderizado de forma dinámica o dicho de otra forma en vez de establecer la configuración del entorno en función de la VRAM que sea el usuario el perfil gráfico que quiere utilizar

Hay multitud de formas de aplicar esta utilidad dentro de tu juego
