/// Constantes del Seeder Bot (deben coincidir con el worker en HunterBot/seeder-bot).
///
/// Por cada target el worker intenta enviar con N perfiles: 1 (bot/botrive) + 1 (factory/botlode)
/// + los perfiles extra (apex, assistify, impresiones, metalwailers, mindset, poncho_spanish).
/// Si en el futuro se agregan más perfiles en HunterBot/seeder-bot (src/metadata.py EXTRA_PROPAGATION_PROFILES),
/// aumentar [seederMaxProfilesPerTarget] aquí para que el badge muestre el máximo correcto (ej. 9/9).
const int seederMaxProfilesPerTarget = 8; // 1 bot + 1 factory + 6 extra
