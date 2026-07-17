# Дипломный проект (iOS, Swift)

Мобильное приложение на iOS демонстрирует модульную архитектуру на основе паттернов **MVVM** и **Coordinator**, интеграцию с **Supabase** (Auth + REST), работу с **Core Data** и локальными сервисами. В рамках диплома реализованы ключевые пользовательские сценарии: авторизация и управление профилем, лента с постами и сторис, модуль музыки с мини‑плеером, экран меню и модуль настроек приложения.

## Оглавление

1. [Общее описание](#общее-описание)
2. [Технологии и стек](#технологии-и-стек)
3. [Архитектура навигации (Coordinator)](#архитектура-навигации-coordinator)
   - [Базовый протокол Coordinator](#базовый-протокол-coordinator)
   - [AppCoordinator](#appcoordinator)
   - [LoginCoordinator](#logincoordinator)
   - [MainCoordinator](#maincoordinator)
   - [RootTabContainerController](#roottabcontainercontroller)
   - [Дочерние координаторы вкладок](#дочерние-координаторы-вкладок)
   - [Коммуникация и расширяемость](#коммуникация-и-расширяемость)
4. [Модуль авторизации и профиля (Supabase + OTP)](#модуль-авторизации-и-профиля-supabase--otp)
   - [Назначение модуля](#назначение-модуля)
   - [Навигация: LoginCoordinator и стартовые экраны](#навигация-loginkoordinator-и-стартовые-экраны)
   - [Бизнес-логика авторизации: LoginInspector и CheckerService](#бизнес-логика-авторизации-logininspector-и-checkerservice)
   - [Supabase AuthService и REST-клиент](#supabase-authservice-и-rest-клиент)
   - [Сервис профиля: SupabaseUserService и модель User](#сервис-профиля-supabaseuserservice-и-модель-user)
   - [Экранный слой: ViewController + ViewModel](#экранный-слой-viewcontroller--viewmodel)
5. [Модуль профиля, постов, историй и фото](#модуль-профиля-постов-историй-и-фото)
   - [Назначение модуля](#назначение-модуля-1)
   - [Архитектура и паттерны](#архитектура-и-паттерны)
   - [Доменные модели и Core Data](#доменные-модели-и-core-data)
   - [Истории (Stories)](#истории-stories)
   - [Посты и избранное](#посты-и-избранное)
   - [Друзья](#друзья)
   - [Фото, альбомы и просмотр](#фото-альбомы-и-просмотр)
   - [Экран профиля](#экран-профиля)
   - [Редактирование профиля и доп. экраны](#редактирование-профиля-и-доп-экраны)
6. [Модуль настроек приложения](#модуль-настроек-приложения)
7. [Экран музыки](#экран-музыки)
8. [Экран меню](#экран-меню)
9. [Экран ленты (Feed)](#экран-ленты-feed)
10. [Репозиторий фотографий SupabasePhotosRepository](#репозиторий-фотографий-supabasephotosrepository)
11. [Сеть и хранение файлов](#сеть-и-хранение-файлов)
12. [Сборка и запуск проекта](#сборка-и-запуск-проекта)
13. [Дальнейшее развитие и расширяемость](#дальнейшее-развитие-и-расширяемость)

---

## Общее описание

Дипломный проект представляет собой iOS‑приложение на UIKit, реализующее функционал:

- авторизация и регистрация пользователей (email/пароль, телефон + OTP);
- профиль пользователя с постами, историями, фото, друзьями и избранным;
- лента (feed) с постами и сторис;
- экран музыки с мини‑плеером;
- экран настроек приложения (уведомления, разрешения, тема, язык, навигация);
- экран меню с быстрым доступом к основным разделам.

Ключевая особенность архитектуры — использование паттерна **Coordinator** для навигации, модульное разбиение функционала и вынос бизнес‑логики в сервисы и ViewModel. В качестве backend‑части используется **Supabase** (Auth + REST), а для локального кеширования — **Core Data**.

---

## Технологии и стек

- **Язык:** Swift
- **UI:** UIKit, UICollectionViewCompositionalLayout, UINavigationController, кастомные контейнеры
- **Архитектура:** MVVM + Coordinator
- **Навигация:** собственная реализация через координаторы
- **Backend:** Supabase (Auth, REST API, таблицы `profiles`, `phone_otp`, альбомы и фото, друзья)
- **Хранение данных:**
  - Core Data (посты, истории, кеш профиля);
  - UserDefaults (настройки приложения);
  - Keychain (авторизационные данные).
- **Мультимедиа:** AVFoundation (AVAudioPlayer) для аудио, PHPickerViewController / UIImagePickerController для фото
- **Сеть:** URLSession + Supabase REST API
- **Локализация и тема:** собственные менеджеры `LocalizationManager`, `ThemeManager`

---

## Архитектура навигации (Coordinator)

### Базовый протокол Coordinator

Все координаторы реализуют общий протокол:

```swift
protocol Coordinator: AnyObject {
    var controller: UIViewController { get set }   // корневой контроллер флоу
    var children: [Coordinator] { get set }       // дочерние координаторы
    func setup()                                  // начальная конфигурация
}
```

Ключевые роли:

- **`controller`** — корневой контроллер конкретного пользовательского сценария (флоу): `UINavigationController` или кастомный контейнер.
- **`children`** — список дочерних координаторов для вложенных флоу (отдельные вкладки таббара, модальные сценарии и т.п.).
- **`setup()`** — единая точка входа, где координатор настраивает стартовый экран и выполняет начальные переходы.

Каждый флоу приложения инкапсулирован в отдельном координаторе с чётко определённым корневым контроллером и набором дочерних флоу.

### AppCoordinator

`AppCoordinator` создаётся при запуске приложения (в `SceneDelegate`) и отвечает за:

- инициализацию общих сервисов уровня приложения: аутентификация, REST‑клиент Supabase, кеши, настройки и т.д.;
- выбор стартового флоу: авторизация или основной сценарий;
- переключение между основным флоу и флоу авторизации при логине/логауте.

Выбор презентации реализован через перечисление:

```swift
enum Presentation {
    case login
    case main(user: User)
}
```

#### Делегаты

- **`LoginCoordinatorDelegate`** — уведомляет `AppCoordinator` об успешной авторизации:
  
  ```swift
  func loginCoordinator(_ coordinator: LoginCoordinator, didLogin user: User)
  ```

- **`MainCoordinatorDelegate`** — уведомляет о запросе логаута:

  ```swift
  func mainCoordinatorDidRequestLogout(_ coordinator: MainCoordinator)
  ```

Вся логика смены глобального состояния приложения (логин/логаут) сосредоточена в одном месте — в `AppCoordinator`.

### LoginCoordinator

`LoginCoordinator` инкапсулирует все сценарии, связанные с авторизацией и регистрацией. Он управляет собственным `UINavigationController` со стеком экранов авторизации.

```swift
enum Presentation {
    case start              // выбор Вход / Регистрация
    case loginCredentials   // вход по email/паролю
    case signUp             // регистрация по email + OTP
    case phoneLogin         // вход по номеру телефона
    case phoneSignUpCode(data: SignUpData, verificationID: String)
}
```

В `setup()` координатор показывает `.start`.

При успешной авторизации он вызывает делегат наверх:

```swift
delegate?.loginCoordinator(self, didLogin: user)
```

Экраны не знают, куда дальше» переходить — они сообщают координатору о событиях, а тот управляет навигацией.

### MainCoordinator

`MainCoordinator` запускается после успешной авторизации и отвечает за основную часть приложения:

- создание и настройку корневого контейнера **`RootTabContainerController`**;
- создание координаторов вкладок:
  - `FeedCoordinator` — лента;
  - `MusicCoordinator` — музыка;
  - `ProfileCoordinator` — профиль пользователя;
  - `MenuCoordinator` — меню.

Дополнительно `MainCoordinator`:

- прокидывает обработчик изменения темы (`onThemeChanged`), чтобы изменения из настроек применялись глобально;
- связывает мини‑плеер с вкладкой музыки (через колбэки `bindMiniPlayer`);
- реализует делегаты `ProfileCoordinatorDelegate` и `MenuCoordinatorDelegate` для обработки событий более высокого уровня (запрос логаута, переходы к друзьям, фото и т.п.).

При получении сигнала о логауте `MainCoordinator` уведомляет `AppCoordinator`, который перестраивает корневой флоу обратно на авторизацию.

### RootTabContainerController

`RootTabContainerController` — кастомный контейнерный контроллер, выступающий корневым контроллером основного флоу. Он объединяет:

- **TabBar** — переключение между разделами;
- **UIPageViewController** — горизонтальные свайпы между вкладками;
- **мини‑плеер** — панель управления воспроизведением над таббаром.

Особенности:

- хранит массив контроллеров вкладок и элементы таббара;
- поддерживает включение/отключение свайпов между вкладками (опция в настройках);
- реализует делегат `RootTabContainerControllerDelegate`, который сообщает о повторном выборе уже активной вкладки (например, повторный тап по «Профиль» приводит к `popToRootViewController`).

### Дочерние координаторы вкладок

Каждая вкладка таббара имеет собственный координатор:

- **`FeedCoordinator`** — лента новостей, сторис, навигация к полноэкранному просмотрщику фото и историй.
- **`MusicCoordinator`** — экран музыки, интеграция с мини‑плеером и сервисом воспроизведения.
- **`ProfileCoordinator`** — профиль, друзья, фото/альбомы, истории, редактирование профиля, избранное, выбор темы и языка.
- **`MenuCoordinator`** — экран меню, навигация к друзьям, фото, музыке, настройкам, избранному, а также выход из аккаунта.

Такое разделение снижает связность между разделами и позволяет развивать их независимо.

### Коммуникация и расширяемость

Взаимодействие между слоями и модулями строится через:

- **делегаты** — события снизу вверх (успешная авторизация, запрос логаута, выбор пункта меню);
- **замыкания (callback’и)** — локальные события (изменение темы, изменение состояния мини‑плеера и т.п.);
- **общие сервисы** — аутентификация, сеть, кеши, воспроизведение музыки и др.

Добавление нового флоу не требует изменения существующих экранов: достаточно добавить новый координатор, подключить его к `AppCoordinator`/`MainCoordinator` и, при необходимости, зарегистрировать новую вкладку в `RootTabContainerController`.

---

## Модуль авторизации и профиля (Supabase + OTP)

### Назначение модуля

Модуль решает задачи:

- выбор сценария авторизации/регистрации;
- вход по email/паролю через Supabase Auth;
- регистрация по email/паролю с созданием профиля в таблице `profiles`;
- вход по номеру телефона с OTP (таблица `phone_otp`);
- загрузка/обновление профиля пользователя через REST‑интерфейс Supabase;
- кеш профиля в Core Data;
- плавное переключение между флоу авторизации и основным флоу через координатор.

Основная цель — вынести всю бизнес‑логику авторизации и работы с профилем в сервисы и инспектор (`LoginInspector`), оставив `ViewController`‑ы максимально тонкими.

### Навигация: LoginCoordinator и стартовые экраны

#### StartViewController

Стартовый экран приложения с логотипом и индикатором загрузки:

- логотип по центру;
- под ним `UIActivityIndicatorView`;
- используется как splash/экран загрузки до выбора флоу.

#### AuthStartViewController

Стартовый экран авторизации:

- логотип в центре;
- две кнопки:
  - «Вход» → `.loginCredentials`;
  - «Регистрация» → `.signUp`.

Не содержит логики авторизации — только сообщает координатору о выбранном сценарии.

#### LoginCoordinator

`LoginCoordinator` управляет всеми экранами авторизации, создаёт свой `UINavigationController` и в `setup()` показывает `.start`. Навигация внутри флоу реализована через `present(_:)` с использованием перечисления `Presentation`.

При успешном входе координатор поднимает событие делегату `LoginCoordinatorDelegate`.

### Бизнес-логика авторизации: LoginInspector и CheckerService

#### LoginDelegateProtocol

Контракт между ViewModel/экранами и доменной логикой:

```swift
protocol LoginDelegateProtocol: AnyObject {
    func checkCredentials(email: String, password: String) async throws
    func signUp(_ data: SignUpData) async throws -> User
    func sendSMSCode(to phone: String) async throws -> String
    func verifySMSCode(verificationID: String, code: String) async throws
    func loadCurrentUserProfile() async throws -> User
    func loginByPhone(_ phone: String) async throws -> User
}
```

ViewModel‑и знают только об этом протоколе и не зависят от конкретных сервисов.

#### LoginInspector

`LoginInspector` реализует `LoginDelegateProtocol` и является фасадом над:

- `CheckerServiceProtocol` — проверка логина/пароля, отправка и проверка OTP;
- `UserServiceProtocol` — работа с таблицей `profiles`;
- `AuthServiceProtocol` — Supabase Auth (email/пароль, access‑token, session);
- `CDUserCacheProtocol` — кеш профиля в Core Data;
- `NetworkStatusServiceProtocol` — статус сети (online/offline).

Сценарии:

- **Вход по email/паролю:**
  - `checkCredentials` → `CheckerService` → `AuthService.signIn`.
  - после успешного входа `loadCurrentUserProfile()` загружает профиль:
    - *online:* сначала Supabase, при ошибке — кеш;
    - *offline:* сразу из кеша, иначе доменная ошибка.

- **Регистрация:**
  - `signUp(_:)` вызывает `checkerService.signUp` (через `AuthService.signUp`);
  - обрабатывает кейс `user_already_exists` (422), пробуя `signIn`;
  - создаёт профиль в `profiles` через `userService.createProfile(for:)`;
  - кеширует пользователя.

- **Вход по телефону (OTP):**
  - `sendSMSCode(to:)` → `SupabaseOTPService.sendCode` (запись в `phone_otp` + логирование кода);
  - `verifySMSCode(verificationID, code)` → проверка кода и срока действия;
  - `loginByPhone(phone)` → поиск профиля по телефону, установка локальной сессии через `authService.setLocalSession(userID:)`, кеширование пользователя.

#### CheckerService + SupabaseOTPService

`CheckerService` оборачивает:

- `AuthService` (Supabase Auth — email/пароль);
- `SupabaseOTPService` (OTP в таблице `phone_otp` через `SupabaseRESTClient`).

`SupabaseOTPService` отвечает за генерацию кода, запись в `phone_otp`, срок действия и валидацию.

### Supabase AuthService и REST-клиент

#### SupabaseAuthService (AuthServiceProtocol)

Функциональность:

- регистрация и вход по email/паролю (`client.auth.signUp`, `client.auth.signIn`);
- хранение и восстановление `userID` и `accessToken` из Keychain;
- локальная «сессия» для логина по телефону (`setLocalSession(userID:)`);
- обновление и получение валидного access‑token (`getValidAccessToken`, `refreshSession`);
- `logout()` — выход и очистка Keychain.

Особенность: в `DEBUG` при падении Supabase Auth предусмотрен fallback на тестового пользователя `developer@test.ru` с фиксированным `userID`.

#### SupabaseRESTClient

Универсальный REST‑клиент для запросов к `https://<project>.supabase.co/rest/v1/...`.

- Автоматически проставляет `Authorization`:
  - `Bearer <accessToken>` — при валидной сессии;
  - `Bearer <anonPublicKey>` — иначе.
- Методы:
  - `perform<T: Decodable>(_:)` — запрос с JSON‑ответом;
  - `performVoid(_:)` — запросы без тела ответа.
- При `401 + "JWT expired"` один раз пробует `authService.refreshSession()` и повторяет запрос.
- Использует `JSONEncoder/Decoder` c стратегиями `convertTo/FromSnakeCase` и кастомной `dateDecodingStrategy` (ISO8601, `yyyy-MM-dd`).

### Сервис профиля: SupabaseUserService и модель User

`SupabaseUserService` реализует `UserServiceProtocol` и инкапсулирует работу с таблицей `profiles` и связанными сущностями (друзья, фото, альбомы).

Базовые операции:

- `createProfile(for:)` — `POST` в `profiles` (upsert по `id`);
- `fetchProfile(userID:)` / `fetchProfile(phone:)` — получение профиля, маппинг `UserProfileDTO → User`, кеширование;
- `updateProfile(user:)` — загрузка текущего пользователя, формирование body только из изменившихся полей, `PATCH` по `id`, повторное чтение и кеш;
- `fetchFriends(for:)` — через таблицу `friendships` и последующие запросы `profiles`.

Дополнительно:

- `setAvatarFromPhoto`, `setCoverFromPhoto` — установка аватара/обложки;
- операции с фото и альбомами (`fetchPhotoAlbums`, `fetchPhotos`, `addPhotoToSaved`, `deletePhoto`).

Доменные модели:

- `User` — доменная модель пользователя;
- `UserProfileDTO` — DTO таблицы `profiles`;
- вспомогательные `Name`, `Gender` для удобства работы.

### Экранный слой: ViewController + ViewModel

#### Вход по email/паролю

- `LogInViewController` — отображает форму входа и взаимодействует с `LoginViewModel`.
- `LoginViewModel` — валидация полей, вызов `LoginDelegateProtocol`, загрузка профиля и проброс `User` наружу через `onSuccess`.

#### Вход по телефону (OTP)

- `PhoneLoginViewController` — два состояния: ввод телефона (`.enterPhone`) и ввод кода (`.enterCode`), маска телефона через `PhoneFormatter`, работа с 6 полями ввода кода.
- `PhoneLoginViewModel` — режимы `.login` / `.signUp`, валидация телефона, отправка и проверка кода, повторные запросы, 60‑секундный таймер, финальный вход или регистрация.

#### Регистрация

- `SignUpViewController` — большая форма с основными полями профиля.
- `SignUpViewModel` — базовая валидация, формирование `SignUpData`, отправка SMS‑кода и переход к экрану ввода кода (через координатор).

---

## Модуль профиля, постов, историй и фото

### Назначение модуля

Модуль реализует:

- **Профиль пользователя:** шапка, аватар, обложка, статус, «о себе», счётчики, табы «Главная/Посты/Фото/Музыка»;
- **Посты:** создание/редактирование/удаление, лайки, просмотры, избранное, публикация на стену, кеш в Core Data;
- **Истории (Stories):** создание из нескольких картинок, хранение в Core Data, просмотр последней истории;
- **Фото:** альбомы и фото пользователя, полноэкранный просмотр и действия (аватар/обложка/сохранённые/удаление);
- **Друзья:** список друзей с вкладками «Все/Онлайн», поиск и сортировки;
- **Редактирование профиля и избранное.**

### Архитектура и паттерны

- MVVM для экранов;
- Coordinator (`ProfileCoordinator`) для навигации;
- Core Data для кешей и историй;
- сервисы (`UserServiceProtocol`, `PostServiceProtocol`, `PhotosRepositoryProtocol` и др.);
- общение VM ↔ VC — через замыкания/делегаты.

Слои:

- **UI:** `UIViewController`/`UICollectionViewController` + кастомные ячейки и хедеры;
- **ViewModel:** бизнес‑логика, состояние, валидации, загрузка;
- **Сервисы и хранилища:** сеть и Core Data;
- **Core Data Stack:** `CoreDataStack.shared`.

### Доменные модели и Core Data

Примеры доменных моделей:

```swift
struct MyPost { /* ... */ }
struct User { /* ... */ }
struct Friend { /* ... */ }
struct Photo { /* ... */ }
struct PhotoAlbum { /* ... */ }
```

Core Data:

```swift
final class CoreDataStack {
    static let shared = CoreDataStack()
    let persistentContainer: NSPersistentContainer
    var viewContext: NSManagedObjectContext { persistentContainer.viewContext }
    func newBackgroundContext() -> NSManagedObjectContext { /* ... */ }
}
```

#### CDPostManager

`CDPostManagerProtocol` обеспечивает сохранение и выборку постов в Core Data (upsert по `(id, ownerID)`, выборка всех постов, по автору, по избранному с фильтром по имени автора, работа с флагами `isFavorite`, `isLiked`, `isOnWall`).

#### CDStoryStorage

`CDStoryStorageProtocol` хранит истории в сущностях `CDUser`, `CDStory`, `CDStoryItem`. Поддерживает сохранение набора слайдов и загрузку последней истории для пользователя.

#### CDUserCache

`CDUserCacheProtocol` кеширует доменную модель `User` в Core Data.

### Истории (Stories)

- **`StoryCreationViewModel`** — создание истории: управление списком картинок, ограничением по количеству слайдов, публикация в `CDStoryStorage`, таймер прогресса (через `StoryTimerProtocol`).
- **`StoryPlayerViewModel`** — просмотр истории: загрузка истории из `CDStoryStorage` или из памяти, пролистывание слайдов, прогресс, отображение «N сек. назад».
- **`StoryViewController`** — универсальный контроллер в режимах `.create` и `.viewOnly`, поддерживает жесты (тап, свайп вниз), интеграцию c PHPicker/UIImagePicker и `PermissionService`.

### Посты и избранное

- **`MyPost`** — доменная модель поста (id, автор, текст, картинка, лайки, просмотры, избранное, флаги и т.д.).
- **`PublishPostViewModel`/`PublishPostViewController`** — создание и редактирование постов, валидация, выбор изображения из галереи/камеры.
- **`FavoritesViewModel`/`FavoritesCollectionViewController`** — экран избранных постов с фильтром по автору и поддержкой разворота текста.

### Друзья

- **`Friend`** и `FriendItem` — доменные и UI‑модели;
- **`FriendsViewModel`** — состояние вкладок «Все/Онлайн», сортировка (по имени/дню рождения), поиск, загрузка друзей через `UserServiceProtocol`;
- **`FriendsCollectionViewController`** — отображение списка друзей с табами, поиском и сортировкой.

### Фото, альбомы и просмотр

- **`Photo`**, **`PhotoAlbum`**, `AlbumType` — доменные модели;
- **`PhotosViewController`** — режимы `.main` (табы «Фото/Альбомы») и `.album` (конкретный альбом), грид 3×N;
- **`PhotosViewerViewController`** — полноэкранный просмотр с горизонтальным paging и контекстным меню действий (аватар/обложка/сохранённые/удаление, режим `viewInPost`).

### Экран профиля

- **`ProfileViewModel`** — главный оркестратор профиля: шапка, посты, фото, друзья, вкладки, состояния. Выполняет перезагрузку профиля с параллельной загрузкой нескольких источников, управляет операциями с постами, фото и друзьями.
- **`ProfileCollectionHandler`** — инкапсулирует `UICollectionViewDataSource/Delegate` для `ProfileViewController`, поддерживает сложный layout и множество типов ячеек (друзья, табы, посты, фото, заглушки и т.д.).
- **`ProfileViewController`** — основной экран профиля с compositional layout, прозрачным навбаром, меню действий (редактирование профиля, история, избранное, настройки, выход), pull‑to‑refresh.

### Редактирование профиля и доп. экраны

- **`ProfileEditViewModel` / `ProfileEditViewController`** — редактирование основных полей профиля, валидация изменений, сохранение через `UserService.updateProfile`, рассылка нотификаций об обновлении пользователя.
- **`ProfileInfoViewModel` / `ProfileInfoViewController`** — нижний лист (bottom sheet) с подробной информацией о пользователе («о себе», город, статус, ДР, подписчики/друзья/подписки).

---

## Модуль настроек приложения

Модуль настроек централизует работу с:

- уведомлениями (ежедневные обновления, локальные уведомления);
- системными разрешениями (камера, фотогалерея);
- темой приложения (системная/светлая/тёмная);
- языком приложения (ru/en);
- поведением навигации (свайпы между вкладками).

### Архитектура

- **Паттерн:** MVVM + Coordinator.
- **Хранение:** `UserDefaults` (через `UserSettingsStorage`).
- **Системные API:** `UNUserNotificationCenter`, `AVFoundation`, `Photos`.
- **Локализация:** `LocalizationManager`.
- **Тема:** `ThemeManager`.

### Ключевые компоненты

- **UI:**
  - `SettingsTableViewController` — главный экран настроек;
  - `ThemeSelectionViewController` — выбор темы;
  - `LanguageSelectionViewController` — выбор языка;
  - `NotificationsFooterView` — футер с текстом и кнопкой «Открыть настройки».

- **ViewModel:**
  - `SettingsViewModel` — строит структуру таблицы из `SettingsSectionViewData` и `SettingsRowViewData`, общается с `UserSettingsStorage`, `LocalNotificationsService`, `PermissionService`, `LocalizationManager` и генерирует выходные события (`onDataChanged`, `onOpenSystemSettings`, `onThemeChanged`, `onLanguageChanged`, `onPermissionDeniedAlert`, `onOpenThemeSelection`, `onOpenLanguageSelection`, `onTabSwipeChanged`).
  - `ThemeSelectionViewModel`, `LanguageSelectionViewModel` — простые VM для экранов выбора.

- **Сервисы:**
  - `UserSettingsStorage` — обёртка над `UserDefaults` (флаги уведомлений, разрешений, тема, язык, свайп табов);
  - `LocalNotificationsService` — управление локальными уведомлениями и статусом авторизации;
  - `PermissionService` — статусы и запросы для камеры/фото + алерты с переходом в системные настройки;
  - `LocalizationManager` — смена языка, локализованные строки;
  - `ThemeManager` — применение темы к окну (`UIWindow`).

Из настроек прокидывается событие `onTabSwipeChanged`, которым `RootTabContainerController` включает/отключает свайпы между вкладками.

---

## Экран музыки

Экран «Музыка» реализует:

- отображение списка треков с вкладками «Главная» и «Мои треки»;
- управление воспроизведением (play/pause/stop, next/previous, seek, repeat);
- интеграцию с мини‑плеером, отображаемым поверх таббара;
- работу через координатор `MusicCoordinator`.

### Архитектура

- **UI:** `MusicCollectionViewController`, `MiniPlayerView`, `MusicTrackCell`, `MusicTabsHeaderView`, `TitleHeaderView`;
- **ViewModel:** `MusicViewModel`, `MiniPlayerViewModel`;
- **Сервисы:** `MusicPlayerService` (протокол), `LocalMusicService` (реализация на AVAudioPlayer);
- **Координатор:** `MusicCoordinator`.

`LocalMusicService` хранит список локальных треков, управляет текущим индексом и режимом повтора, обновляет состояние через `onStateChanged`. `MiniPlayerViewModel` и `MusicViewModel` подписаны на изменения `PlayerState` и обновляют UI.

---

## Экран меню

Экран меню отображает профиль текущего пользователя и сетку пунктов меню.

- **UI:** `MenuCollectionViewController` с compositional layout (секция профиля + секция меню), `ProfileCell`, `MenuItemCell`, `MenuHeaderView`.
- **ViewModel:** `MenuViewModel` — хранит текущего пользователя и список пунктов меню, подписывается на нотификации об обновлении пользователя.
- **Координатор:** `MenuCoordinator` — обрабатывает выбор пунктов меню и пробрасывает их наружу через `MenuCoordinatorDelegate` (переход к друзьям, архиву историй, фото, музыке, избранному, настройкам, редактирование профиля, логаут, экран «О приложении»).

Комповка реализована через `UICollectionViewCompositionalLayout` с 4 колонками в секции меню.

---

## Экран ленты (Feed)

Экран ленты показывает сторисы и посты пользователя.

- **UI:** `FeedCollectionViewController`, `PostCollectionViewCell`, `StoryCollectionViewCell`, `TitleHeaderView`;
- **ViewModel:** `MainFeedViewModel`, `FeedStoriesViewModel`, `FeedPostsViewModel`;
- **Сервисы:** `LocalFeedService`, `LocalStoryService`, `PostServiceProtocol`, `PhotosRepositoryProtocol`;
- **Координатор:** `FeedCoordinator` — навигация к Story Viewer и Photo Viewer.

Функциональность:

- горизонтальная лента сторис;
- вертикальный список постов;
- лайки, избранное, просмотры, репосты на стену;
- просмотр фото поста в полноэкранном вьюере с возможностью добавить в «сохранённые»;
- pull‑to‑refresh и параллельная загрузка сторис/постов.

`MainFeedViewModel` агрегирует `FeedStoriesViewModel` и `FeedPostsViewModel`, обеспечивает единый API для контроллера и маппит частичные обновления секций в перерисовку коллекции.

---

## Репозиторий фотографий SupabasePhotosRepository

`SupabasePhotosRepository` — реализация `PhotosRepositoryProtocol` поверх `SupabaseUserService`.

Отвечает за:

- загрузку фотоальбомов и фотографий пользователя;
- маппинг DTO Supabase в доменные модели `PhotoAlbum` и `Photo`;
- операции над фотографиями: удаление, установка аватара/обложки, добавление в «сохранённые».

Все методы асинхронные, могут бросать ошибки сети/Supabase. Внешний код работает только с доменными моделями и не зависит от деталей реализации Supabase.

---

## Сеть и хранение файлов

Сетевое взаимодействие реализовано через Supabase REST API и собственный REST‑клиент. Для аутентификации используется Supabase Auth.

**Важно:** изначально планировалась загрузка файлов в **Supabase Storage**, однако из‑за сетевых ограничений региона (таймауты по HTTPS к Storage) в итоговой версии используется **хранение только ссылок на уже доступные в интернете изображения**. Это упростило работу с мультимедиа и повысило надёжность в условиях нестабильного соединения.

---

## Сборка и запуск проекта

### Требования к среде

- **Xcode:** 15.x (минимум 14.x)
- **iOS Deployment Target:** 15.0 или выше
- **Swift:** 5.7+
- **Интернет‑доступ:** для работы с Supabase REST и Auth

### Учёт DEBUG/RELEASE

- В `DEBUG` предусмотрен fallback на тестового пользователя для Supabase Auth.
- Для реального деплоя необходимо настроить корректные ключи Supabase и отключить тестовые заглушки.

---

## Дальнейшее развитие и расширяемость

Архитектура проекта ориентирована на расширяемость:

- **Новые флоу:** добавляются через новые координаторы, подключаемые к `AppCoordinator`/`MainCoordinator`.
- **Новые вкладки:** достаточно расширить конфигурацию `RootTabContainerController` и создать соответствующий координатор.
- **Новые модули:** подключаются как самостоятельные подсистемы (MVVM + Coordinator + сервисы), использующие общие инфраструктурные сервисы (Auth, REST, кеши, настройки).
- **Backend:** при необходимости Supabase можно заменить или дополнить другим backend‑решением, сохранив интерфейсы сервисов (`UserServiceProtocol`, `PhotosRepositoryProtocol`, `PostServiceProtocol` и др.).

Такой подход делает проект удобным для дальнейшей доработки, экспериментов с UI/UX и масштабирования функциональности в рамках учебных и реальных задач.

