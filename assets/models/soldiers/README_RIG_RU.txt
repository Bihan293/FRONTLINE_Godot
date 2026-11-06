FRONTLINE — RIGGED SOLDIERS v1

ФАЙЛЫ
- FRONTLINE_IRON_LEGION_Soldier_RIG_v1.glb
- FRONTLINE_RED_FRONT_Soldier_RIG_v1.glb
- FRONTLINE_ProceduralSoldier.gd

ЧТО ДОБАВЛЕНО
Обе модели используют одинаковую 20-костную humanoid-иерархию:
Root, Hips, Spine, Chest, Neck, Head;
Left/RightShoulder, UpperArm, LowerArm, Hand;
Left/RightUpperLeg, LowerLeg, Foot.

Геометрия каждой отдельной части привязана к соответствующей кости с весом 1.0.
Это намеренный rigid low-poly rig: прямоугольные рукава, ботинки, каска и подсумки
не растягиваются как резина при сгибании. Модель остаётся в исходной T-позе.

GODOT 4 — ПОДКЛЮЧЕНИЕ
1. Скопируйте оба GLB и FRONTLINE_ProceduralSoldier.gd в проект Godot.
2. Импортируйте GLB и откройте сцену модели.
3. Проверьте, что импортёр создал Skeleton3D и кости с указанными именами.
4. Создайте CharacterBody3D (или другой корневой узел), добавьте внутрь инстанс GLB.
5. Прикрепите FRONTLINE_ProceduralSoldier.gd к корню персонажа.
6. Укажите skeleton_path до Skeleton3D. Если Skeleton3D находится глубже, укажите полный относительный NodePath.
7. Из контроллера движения вызывайте:
   $ProceduralSoldier.set_motion(horizontal_speed, is_running)
   $ProceduralSoldier.set_look(camera_yaw, camera_pitch)
   $ProceduralSoldier.set_aiming(is_aiming)
   $ProceduralSoldier.set_crouching(is_crouching)
   $ProceduralSoldier.set_firing(is_firing)

ВАЖНО
- Скрипт — процедурная стартовая система, а не копия внутренней анимационной системы Scorched Earth.
- Он задаёт базовую походку, бег, приседание, поворот головы и положение рук при прицеливании.
- Для качественного FPS ещё потребуются синхронизация ног с фактической скоростью, foot planting,
  IK для кистей на цевье/рукояти, recoil, additive hit reactions, наклон корпуса в повороте,
  переходы стоя/присед/лёжа и проверка поз в самом Godot.
- Точные оси вращения и путь к Skeleton3D нужно проверить после импорта в конкретную версию Godot.
- Godot runtime в этой среде не запускался. GLB проверены на структуру glTF 2.0, skin,
  inverse bind matrices, JOINTS_0 и WEIGHTS_0; это не заменяет тест импортёра Godot.
