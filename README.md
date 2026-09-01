# ZiutekCraft Afterfall Terminal

Terminal informacyjny na spawn serwera **ZiutekCraft Afterfall**, przygotowany pod **CC:Tweaked** i ścianę monitorów **5 szerokości x 3 wysokości**.

## Co jest potrzebne

- 1x Advanced Computer / Computer z CC:Tweaked
- monitory CC:Tweaked połączone w prostokąt 5x3
- komputer podłączony bezpośrednio do dowolnego monitora z tej ściany
- włączone HTTP w konfiguracji CC:Tweaked
- opcjonalnie Advanced Peripherals Player Detector do automatycznej liczby graczy online

## Instalacja

Na komputerze CC:Tweaked wpisz:

```lua
wget run https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/install.lua
```

Instalator pobierze `startup.lua` i zrestartuje komputer.

## Ręczna instalacja

```lua
wget https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/startup.lua startup.lua
reboot
```

## Układ monitora

Ustaw ścianę monitorów tak:

```text
[M][M][M][M][M]
[M][M][M][M][M]
[M][M][M][M][M]
```

Wszystkie monitory muszą się stykać bokami, aby CC:Tweaked potraktował je jako jeden ekran.

## Funkcje

- animacja startowa Afterfall
- ekran statusu sieci i bunkra
- lista podstawowych komend dla nowych graczy
- rotujące komunikaty fabularne
- zegar
- liczba graczy online, jeśli wykryty zostanie Player Detector
- automatyczny start po restarcie chunku/serwera/komputera

## Aktualizacja

Aby pobrać najnowszą wersję, ponownie uruchom:

```lua
wget run https://raw.githubusercontent.com/koryzmapiotr0-tech/ziutekcraft-afterfall-terminal/main/install.lua
```

Repozytorium jest publiczne, więc terminal może pobierać aktualizacje bez tokenu GitHub.
