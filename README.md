# ZiutekCraft Afterfall Terminals

Dwa interaktywne ekrany **CC:Tweaked** na spawn serwera ZiutekCraft Afterfall, przygotowane pod sciany **Advanced Monitor 5 szerokosci x 3 wysokosci**.

## Ekran 1 - Terminal Ocalalych

Publiczny terminal dla nowych graczy:

- START / status spawnu
- Jak zaczac
- Historia Afterfall
- Questy
- Ekonomia
- Technologie
- Status swiata
- Pomoc
- Archiwum
- obsluga dotyku Advanced Monitora
- liczba graczy przez Player Detector
- dane swiata przez Environment Detector

### Instalacja ekranu 1

Na **pierwszym komputerze** CC:Tweaked wpisz:

```lua
wget run https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/install.lua
```

---

## Ekran 2 - Afterfall Command Center

Centrum dowodzenia i telemetrii:

- Centrala / dashboard operacyjny
- Ocalali - liczba i lista graczy online
- Swiat - biom, wymiar, pogoda, czas, ksiezyc i oswietlenie
- promieniowanie Mekanismu przez Environment Detector
- Radio - archiwum i nowe wiadomosci
- Alerty - NORMALNY / UWAGA / ALARM / KRYTYCZNY
- Eventy - aktywne wydarzenie globalne
- dotykowe menu
- automatyczne odswiezanie
- Rednet do odbierania komunikatow z innych komputerow

### Instalacja ekranu 2

Postaw **drugi osobny komputer CC:Tweaked** przy drugiej scianie monitorow 5x3 i wpisz:

```lua
wget run https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/install_command_center.lua
```

Instalator zapisze Command Center jako `startup.lua` na tym drugim komputerze i wykona restart.

---

## Co postawic

Dla pelnej konfiguracji spawnu:

```text
TERMINAL OCALALYCH             COMMAND CENTER
[M][M][M][M][M]                [M][M][M][M][M]
[M][M][M][M][M]                [M][M][M][M][M]
[M][M][M][M][M]                [M][M][M][M][M]
       |                               |
 [Computer #1]                  [Computer #2]
```

Kazda sciana musi byc zbudowana z **Advanced Monitorow**, jezeli ma reagowac na klikniecia.

## Zalecane peryferia

Do Command Center podlacz bezposrednio lub przez **Wired Modem + Networking Cable**:

- **Player Detector** - lista i liczba graczy online
- **Environment Detector** - biom, wymiar, pogoda, czas, oswietlenie i promieniowanie
- **Wired/Wireless Modem** - komunikaty Rednet

Na Minecraft 1.21.1 program korzysta z nowych nazw peryferiow:

- `player_detector`
- `environment_detector`

ale zawiera tez fallback dla starszych nazw.

## Rednet - Command Center

Command Center reaguje na trzy protokoly:

- `afterfall.radio` - nowy komunikat radiowy
- `afterfall.event` - aktywny event
- `afterfall.alert` - poziom alarmu

Przyklad wyslania komunikatu z innego komputera CC:Tweaked:

```lua
rednet.broadcast({
  level = "UWAGA",
  title = "SEKTOR 04",
  text = "Wykryto nieznany sygnal na polnoc od bunkra."
}, "afterfall.radio")
```

Zmiana alertu:

```lua
rednet.broadcast("ALARM", "afterfall.alert")
```

Powrot do automatycznego alertu:

```lua
rednet.broadcast("AUTO", "afterfall.alert")
```

Event:

```lua
rednet.broadcast({
  title = "AWARIA SIECI",
  text = "Ocalali maja zabezpieczyc awaryjne zrodla energii."
}, "afterfall.event")
```

## Pliki lokalne Command Center

Bez Rednetu mozna tez ustawic informacje plikami na komputerze Command Center.

`/afterfall_event.txt`:

```text
NAZWA EVENTU
Opis wydarzenia wyswietlany na ekranie.
```

`/afterfall_alert.txt`:

```text
ALARM
```

Dostepne poziomy: `NORMALNY`, `UWAGA`, `ALARM`, `KRYTYCZNY`.

## Aktualizacja

Ekran 1:

```lua
wget run https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/install.lua
```

Ekran 2:

```lua
wget run https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/install_command_center.lua
```
