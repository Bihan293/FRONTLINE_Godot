# itch.io page draft — FRONTLINE

> Статус: **черновик, не опубликовано.** Публикация — только после подписи `RELEASE_GATE.md`.
> Обновлено: 07.11.2026, `main @ 264d6a9` (PR #9).

## Название

**FRONTLINE — Low-Poly Tactical FPS**

Короткий вариант для карточки: **FRONTLINE**

## Короткое описание (RU)

Низкополигональный тактический FPS про бой двух фракций: окопы, деревня, боты, роли, техника ближнего боя и физика рэгдолла. Играй за Железный Легион или Красный Фронт, захватывай сектора и держи линию фронта.

## Short description (EN)

A low-poly tactical FPS about two factions holding the line: trenches, a village, bot squads, combat roles and ragdoll physics. Fight for the Iron Legion or the Red Front, capture sectors and hold the front.

## Что уже есть

- **2 боевые карты:** Battlefield (240×180 м, траншеи и руины) и Village (180×150 м, дома, церковь, мельница) + тренировочный Polygon.
- **8 видов оружия:** AK-47, MP-40, Mosin-Nagant, M1911, Pump Shotgun, PPSh-41, Kar98k, Panzerfaust.
- **Роли:** штурмовик, медик, снайпер, противотанковый боец, радист с управляемым дроном.
- **Режимы:** Conquest (3 сектора + ticket bleed) и Team Deathmatch (до 50 фрагов).
- **Боты:** 7–14 на сторону, A*-навигация, укрытия, гранаты, дым, роли, 3 уровня сложности.
- **Снаряжение:** осколочные и дымовые гранаты, бинты, взрывные бочки, ящики патронов, подбор оружия.
- **Физика:** рэгдолл, кровь, гильзы, взрывы, попадания по зонам.
- **HUD:** компас, круглая мини-карта, киллфид, счёт, экран победы, пауза, настройки чувствительности/FOV.
- **Android:** сенсорный джойстик, свайп-обзор, отдельные кнопки огня/прицела/перезарядки/гранат/бинта.

## Чего пока нет (честно)

- Техники (джип/танк), стационарных турелей и полноценной песочницы.
- 4+ карт и 3+ режимов — в работе.
- Онлайн-мультиплеера.
- Полноценной прогрессии/рангов.
- Публичной сборки на itch.io.

## Управление

### ПК
- WASD / стрелки — движение
- Мышь — обзор, ЛКМ — огонь, ПКМ — прицел
- R — перезарядка, C — присесть/лечь, Space — встать/прыжок
- G — граната, X/T — дым, H — бинт, 1–8 / колесо — оружие
- Q/E — наклон, ESC — пауза, TAB — табло

### Android
- Левый джойстик — движение (до края — бег)
- Свайп вне кнопок — обзор
- Кнопки: ОГОНЬ, ПРИЦЕЛ, ПЕРЕЗАР., ПРИСЕСТЬ, ПРЫЖОК, ГРАНАТА, ДЫМ, БИНТ, ВЗЯТЬ, ДРОН
- II — пауза, ТАБЛО — счёт

## Скриншоты для страницы

Порядок для галереи:

1. `screenshots/03_battlefield_overview.png` — обзор Battlefield
2. `screenshots/04_battlefield_hud.png` — бой и HUD
3. `screenshots/06_village_overview.png` — обзор Village
4. `screenshots/07_village_hud.png` — улица деревни
5. `screenshots/05_pause_menu.png` — пауза
6. `screenshots/02_settings.png` — настройки
7. `screenshots/01_main_menu.png` — меню

Все кадры 1280×720, сняты из реального билда через `tools/screenshot_harness.tscn`.

## Теги

`fps`, `first-person`, `low-poly`, `war`, `military`, `shooter`, `singleplayer`, `bots`, `sandbox`, `android`, `godot`

## Платформы и сборки

- Android APK: GitHub Releases — https://github.com/Bihan293/FRONTLINE_Godot/releases/latest
- Windows/Linux: экспорт ещё не настроен.
- Web: не проверялся.

## Медиа и пресс-кит

- Логотип: `icon.svg`
- Скриншоты: `screenshots/`
- Инструмент съёмки: `tools/screenshot_harness.tscn`
- Трейлер/GIF: **нужно записать** (пока нет).

## Кредиты и лицензии

- Звук: CC0 — Tabasco («Gunshot sound effect»), Kenney («Impact Sounds», «Interface Sounds»). См. `assets/audio/LICENSE.md`.
- Остальные ассеты: проверить лицензии перед публикацией (пункт `RELEASE_GATE.md`).
- Движок: Godot 4.3.

## Чек-лист публикации

- [ ] Все пункты `RELEASE_GATE.md` закрыты и подписаны.
- [ ] APK проверен на чистом Android-устройстве.
- [ ] Описание и скриншоты загружены.
- [ ] Указаны лицензии и кредиты.
- [ ] Записан короткий трейлер или GIF.
- [ ] Указана цена (free) и кнопка скачивания.
- [ ] Ссылка на GitHub Releases и сообщение о багах.
