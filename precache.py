#!/usr/bin/env python3
"""
Genera un cache pre-construido de traducciones usando Gemini API.

Uso:
  GEMINI_API_KEY=tu_clave python3 precache.py

Genera: Parla/Resources/PrecachedTranslations.json
"""

import json, os, sys, time, urllib.request

# === Configuracion ===

MODEL = "gemini-2.5-flash"
ENDPOINT = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent"
DELAY_BETWEEN_REQUESTS = 1.5  # segundos (free tier rate limit)
MAX_RETRIES = 3

# === System prompt (cargado desde archivo) ===

SYSTEM_PROMPT_PATH = "Parla/Resources/GeminiSystemPrompt.txt"

def load_system_prompt():
    try:
        with open(SYSTEM_PROMPT_PATH, encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        print(f"ERROR: No se encuentra {SYSTEM_PROMPT_PATH}", file=sys.stderr)
        sys.exit(1)

# === Frases (merge deduplicado de ambas rondas) ===

PHRASES_NEW_TO_BOOMER = [
    "Bro eso fue cringe",
    "No cap ese pibe tiene rizz god",
    "Mi crush me ghosteo",
    "Estoy en mi villain era",
    "Esa bestie tiene flow",
    "Todo Gucci",
    "Periodt",
    "Ese NPC es un simp total",
    "La esta petando",
    "Estoy flipando",
    "Me da mucho cringe",
    "Tiene mucho lore",
    "Spill the tea bestie",
    "F en el chat",
    "Es PEC",
    "Six seven bro",
    "Ese flexero no para de frontear",
    "Me tienen rayado",
    "Literal me muero",
    "En plan no se que hacer",
    "Ese tryhard es un hater",
    "Caught in 4K stalkeando",
    "Mucho texto bro",
    "Estoy en un brainrot heavy",
    "Mi crush me tiene rent free",
    "Es que su fit esta god",
    "Ese sigma va por libre",
    "Lowkey me gusta",
    "Highkey es lo mejor",
    "Devoro con ese outfit",
    "Red flag total",
    "Green flag ese pibe",
    "Le dio el ick",
    "Estamos en el talking stage",
    "Es un situationship",
    "Skibidi bro",
    "Plot twist increible",
    "Evento canonico",
    "Main character energy",
    "Es giving boomer",
    "Touch grass bro",
    "Understood the assignment",
    "Y la queso",
    "Te falta lore",
    "Es muy random",
    "Ese beat es un banger",
    "Esta chetado",
    "Carrileo todo el proyecto",
    "Lo funaron por toxico",
    "Le baneo de su vida",
    "Bro que haces esta noche",
    "Eso es cap",
    "No tienes rizz bro",
    "Ese pibe es un chad total",
    "Estoy dead de la risa",
    "Ngl eso estuvo fire",
    "Es giving main character energy",
    "Esa cancion es un banger",
    "Me siento NPC hoy",
    "Bro necesito un glow up",
    "Ese beef fue epico",
    "Le tiro shade delante de todos",
    "Estoy en mi gym era",
    "Ese hater no para",
    "Es un nepobaby total",
    "Me rayo demasiado",
    "Bro eso es sus",
    "Ese fit esta snatched",
    "Farmeo aura en las redes",
    "No me ghostees porfa",
    "Ese stan es muy intenso",
    "Vaya plot twist con lo de ayer",
    "Todo es muy aesthetic",
    "Puro postureo",
    "Eres un crack bro",
    "Que vibe tiene este sitio",
    "Me tiene en un brainrot",
    "Estoy en el talking stage con alguien",
    "Bro soy sigma ahora",
    "Ate and left no crumbs",
    "Ese noob no sabe nada",
    "Es mid la verdad",
    "Tiene mucha red flag",
    "Me hizo un fanum tax con mi bocadillo",
    "Deja de trolear bro",
    "Me baneo del grupo",
    "Esa pelicula flopeo",
    "Bro eso es malardo",
    "Tiene un lore increible",
    "Solo quiero mimir",
    "Messirve para el examen",
    "Que dou lo de anoche",
    "GG bro bien jugado",
    "Es god tier ese plato",
    "Menudo glow up ha pegado",
    "Su drip es impecable",
    "El salseo de hoy esta fuerte",
    "Bro vamos a perrear",
    "Ese pibe spawneo de la nada",
    "Nasheee que bueno",
    "Factos bro factos",
    "Spill the tea que paso",
    "Estamos en un situationship raro",
    "Fr fr no miento",
    "Ese tio es un tryhard",
    "Bro touch grass un poco",
    "La funaron en twitter",
    "Ese sneaky link me tiene loco",
    "Eso fue caught in 4K total",
    "Es un evento canonico en mi vida",
]

PHRASES_BOOMER_TO_NEW = [
    "Eso fue bochornoso",
    "Ese chico tiene mucho encanto",
    "Me dejo de hablar",
    "Estoy en plan egoista",
    "Esa amiga tiene elegancia",
    "Todo en orden",
    "Asunto zanjado",
    "Ese borreguito es un baboso",
    "Esta arrasando",
    "Estoy atonito",
    "Me da verguenza ajena",
    "Eso tiene miga",
    "Cuentamelo todo",
    "Vaya mala suerte",
    "Es magnifico",
    "Pan comido",
    "Ese presumido no para de pavonearse",
    "Estoy agobiado",
    "Madre mia que fuerte",
    "No se que hacer la verdad",
    "Ese empollón es un envidioso",
    "Pillado con las manos en la masa espiando",
    "No te enrolles tanto",
    "Estoy con la cabeza como un bombo",
    "Esa chica me tiene loco perdido",
    "Fijate que buen conjunto lleva",
    "Ese va a su bola",
    "Me gusta un poquito",
    "Es lo mejor sin duda",
    "Arraso con ese vestido",
    "Mala espina total",
    "Buen muchacho ese",
    "Le entro tirria de repente",
    "Estamos conociéndonos",
    "Somos amigos especiales",
    "Menuda tonteria",
    "Vaya giro inesperado",
    "Momento decisivo",
    "Se cree la estrella",
    "Eso parece cosa de viejo",
    "Sal a la calle un poco",
    "Se lucio de lo lindo",
    "Y al que no le guste que se aguante",
    "No sabes ni la mitad",
    "De la nada total",
    "Menudo temazo",
    "Es invencible",
    "Llevo todo el peso del proyecto",
    "Lo denunciaron por posesivo",
    "Lo aparto de su vida",
    "Que haces esta noche amigo",
    "Eso es mentira",
    "Ese chico no tiene encanto",
    "Ese muchacho es todo un hombre",
    "Me estoy muriendo de risa",
    "Eso estuvo espectacular de verdad",
    "Se cree el centro del universo",
    "Menudo temazo de cancion",
    "Hoy me siento un borreguito",
    "Necesito un cambio radical",
    "Menuda bronca entre esos dos",
    "Le lanzo indirectas delante de todos",
    "Estoy en mi etapa de gimnasio",
    "Ese envidioso no para de criticar",
    "Es un enchufado total",
    "Le doy demasiadas vueltas a todo",
    "Eso es sospechoso",
    "Ese conjunto le sienta de maravilla",
    "Se esta labrando reputacion en las redes",
    "No me dejes de hablar por favor",
    "Ese admirador es muy intenso",
    "Vaya giro con lo de ayer",
    "Todo tiene un estilo muy cuidado",
    "Pura fachada",
    "Eres un fenomeno amigo",
    "Que buen ambiente tiene este sitio",
    "Esa chica me tiene obsesionado",
    "Estamos en la fase de conocernos",
    "Voy a mi bola",
    "Lo hizo perfecto sin dejar nada",
    "Ese novato no tiene ni idea",
    "Es mediocre la verdad",
    "Tiene mala pinta esa persona",
    "Me quito el bocadillo el muy descarado",
    "Deja de provocar hombre",
    "Me echaron del grupo",
    "Esa pelicula fue un fracaso",
    "Eso es espantoso",
    "Tiene una historia detras increible",
    "Solo quiero dormir",
    "Me viene bien para el examen",
    "Madre mia lo de anoche",
    "Enhorabuena bien jugado",
    "Esa comida esta de primera",
    "Menudo cambiazo ha dado",
    "Su estilo es impecable",
    "El cotilleo de hoy es fuerte",
    "Vamos a bailar",
    "Aparecio de la nada ese chico",
    "Perfecto que bueno",
    "Efectivamente asi es",
    "Cuenta que paso",
    "Tenemos una relacion rara sin definir",
    "De verdad que no miento",
    "Ese chico se esfuerza demasiado",
    "Esa muchacha es pura fachada",
    "El presumido no para de pavonearse",
    "Hay que ver la verguenza ajena que da",
    "En mis tiempos esto se hacia de otra manera",
    "Fijate tu lo que ha pasado",
    "Menudo bochorno",
    "No te enrolles y ve al grano",
    "Ese chico me da mala espina",
]


def translate(text, source, target, api_key, system_prompt):
    """Traduce una frase usando Gemini API con reintentos."""
    prompt = f"[{source} → {target}] {text}"
    body = json.dumps({
        "contents": [{"parts": [{"text": prompt}]}],
        "systemInstruction": {"parts": [{"text": system_prompt}]},
        "generationConfig": {
            "temperature": 0.6,
            "topP": 0.9,
            "maxOutputTokens": 256,
        },
    }).encode()

    url = f"{ENDPOINT}?key={api_key}"

    for attempt in range(MAX_RETRIES):
        try:
            req = urllib.request.Request(
                url, data=body,
                headers={"Content-Type": "application/json"},
            )
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read())

            content = data["candidates"][0]["content"]["parts"][0]["text"].strip()
            if content:
                return content
        except urllib.error.HTTPError as e:
            if e.code == 429:
                wait = (attempt + 1) * 5
                print(f"  Rate limit, esperando {wait}s...", file=sys.stderr)
                time.sleep(wait)
                continue
            print(f"  HTTP {e.code}: {e.reason}", file=sys.stderr)
        except Exception as e:
            print(f"  ERROR: {e}", file=sys.stderr)

        if attempt < MAX_RETRIES - 1:
            time.sleep(2)

    return None


def main():
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("ERROR: Define GEMINI_API_KEY como variable de entorno", file=sys.stderr)
        sys.exit(1)

    system_prompt = load_system_prompt()

    # Cargar cache existente si existe
    cache_path = "Parla/Resources/PrecachedTranslations.json"
    try:
        with open(cache_path, encoding="utf-8") as f:
            cache = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        cache = {}

    existing = len(cache)
    total_phrases = len(PHRASES_NEW_TO_BOOMER) + len(PHRASES_BOOMER_TO_NEW)
    done = 0
    added = 0

    print(f"Cache existente: {existing} entradas")
    print(f"Procesando {total_phrases} frases...")
    print()

    # New Gen → Boomer
    for phrase in PHRASES_NEW_TO_BOOMER:
        done += 1
        key = f"Nuevas generaciones>Boomer>{phrase.lower().strip()}"
        if key in cache:
            print(f"[{done}/{total_phrases}] NG→B: {phrase[:40]}... YA EXISTE")
            continue
        print(f"[{done}/{total_phrases}] NG→B: {phrase[:40]}...", end=" ", flush=True)
        result = translate(phrase, "Nuevas generaciones", "Boomer", api_key, system_prompt)
        if result:
            cache[key] = result
            added += 1
            print(f"OK ({len(result)} chars)")
        else:
            print("SKIP")
        time.sleep(DELAY_BETWEEN_REQUESTS)

    # Boomer → New Gen
    for phrase in PHRASES_BOOMER_TO_NEW:
        done += 1
        key = f"Boomer>Nuevas generaciones>{phrase.lower().strip()}"
        if key in cache:
            print(f"[{done}/{total_phrases}] B→NG: {phrase[:40]}... YA EXISTE")
            continue
        print(f"[{done}/{total_phrases}] B→NG: {phrase[:40]}...", end=" ", flush=True)
        result = translate(phrase, "Boomer", "Nuevas generaciones", api_key, system_prompt)
        if result:
            cache[key] = result
            added += 1
            print(f"OK ({len(result)} chars)")
        else:
            print("SKIP")
        time.sleep(DELAY_BETWEEN_REQUESTS)

    # Guardar
    with open(cache_path, "w", encoding="utf-8") as f:
        json.dump(cache, f, ensure_ascii=False, indent=2)

    print(f"\nAnadidas: {added} traducciones nuevas")
    print(f"Total cache: {len(cache)} traducciones")
    print(f"Archivo: {cache_path}")


if __name__ == "__main__":
    main()
