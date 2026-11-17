pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/snowfall"

    readonly property int level: adapter.level
    readonly property bool accumulate: adapter.accumulate
    readonly property bool melt: adapter.melt
    readonly property bool bottom: adapter.bottom
    readonly property bool bottomAuto: adapter.bottomAuto
    readonly property real bottomOffset: adapter.bottomOffset
    readonly property real bottomMax: adapter.bottomMax
    readonly property bool windowSnow: adapter.windowSnow
    readonly property real windowMax: adapter.windowMax
    readonly property real growSeconds: adapter.growSeconds
    readonly property int clearTick: adapter.clearTick
    readonly property int tractorTick: adapter.tractorTick
    readonly property real windStrength: adapter.windStrength
    readonly property bool windGust: adapter.windGust
    readonly property real brushSize: adapter.brushSize
    readonly property real ballGrow: adapter.ballGrow
    readonly property real ballMax: adapter.ballMax
    readonly property real luck: adapter.luck
    readonly property bool snowmenOn: adapter.snowmenOn
    readonly property bool announce: adapter.announce
    readonly property string foundJson: adapter.foundJson
    readonly property int tractorMode: adapter.tractorMode
    readonly property int vehicle: adapter.vehicle
    readonly property bool paused: adapter.paused
    readonly property bool gameMode: adapter.gameMode
    readonly property bool saveMode: adapter.saveMode
    readonly property bool dance: adapter.dance
    readonly property bool interactive: adapter.interactive
    readonly property real vehicleOpacity: adapter.vehicleOpacity
    readonly property real vehicleScale: adapter.vehicleScale
    readonly property real snowOpacity: adapter.snowOpacity
    readonly property bool garland: adapter.garland
    readonly property bool garlandTop: adapter.garlandTop
    readonly property bool garlandWin: adapter.garlandWin
    readonly property bool garlandIce: adapter.garlandIce
    readonly property bool garlandFrame: adapter.garlandFrame
    readonly property bool garlandGround: adapter.garlandGround
    readonly property bool garlandMan: adapter.garlandMan
    readonly property int garlandMode: adapter.garlandMode
    readonly property int garlandPalette: adapter.garlandPalette
    readonly property real garlandBright: adapter.garlandBright
    readonly property real garlandSpeed: adapter.garlandSpeed
    readonly property real garlandSize: adapter.garlandSize
    readonly property var garlandColors: {
        var gi = Math.max(0, Math.min(3, adapter.garlandPalette));
        if (gi === 0) return ["#ff4d4d", "#ffb020", "#4cd964", "#3d9bff", "#ff5fa8"];
        if (gi === 1) return ["#ffd9a0", "#ffc878", "#ffe3b8"];
        if (gi === 2) return ["#cfe8ff", "#9ccaff", "#ffffff"];
        return [accent, Qt.lighter(accent, 1.45), Qt.darker(accent, 1.15)];
    }
    readonly property var palette: ["#7fb4d6", "#8ad4b0", "#e08a9a", "#e0b86a", "#a58be0", "#d0d6dc"]
    readonly property int accentIdx: adapter.accentIdx
    readonly property string lang: adapter.lang
    property real uiReveal: 1
    readonly property bool isUk: lang === "uk" || (lang === "auto" && Qt.locale().name.indexOf("uk") === 0)

    function tr(k) {
        var d = isUk ? uk : en;
        if (d[k] !== undefined) return d[k];
        return en[k] !== undefined ? en[k] : k;
    }

    readonly property var en: ({
        sub: "snow, snowmen and a Christmas truck",
        clear: "Clear snow", send: "Send vehicle",
        tabSettings: "Settings", tabCollection: "Collection",
        level: "Snow level", lvl0: "Off", lvl1: "Light", lvl2: "Steady", lvl3: "Heavy", lvl4: "Variable",
        snowOpacity: "Snow opacity",
        presets: "Presets", pCozy: "Cozy", pStorm: "Blizzard", pMin: "Minimal",
        transport: "Vehicle", vTruck: "Truck", vSleigh: "Sleigh", vRandom: "Random",
        vehOpacity: "Vehicle opacity", truckSize: "Truck size",
        theme: "Theme color", language: "Language",
        modes: "Modes",
        garland: "Christmas lights", garlandOn: "Show lights", garlandOnHint: "string lights around the screen",
        gTop: "Top of the screen", gTopHint: "swags under the top bar",
        gWin: "Window tops", gWinHint: "lights on the snow caps",
        gIce: "Icicle lights", gIceHint: "hanging from window edges",
        gFrame: "Screen frame", gFrameHint: "one loop around the whole screen",
        gGround: "On the snow", gGroundHint: "lying along the bottom snow pile",
        gMan: "On snowmen", gManHint: "a string around each snowman",
        gMode: "Animation", gm0: "Steady", gm1: "Twinkle", gm2: "Chase", gm3: "Music",
        gModeHint: "Music: the lights flash on the beat (needs cava; without it they keep a steady 120 BPM), otherwise they glow softly.",
        gPal: "Colors", gp0: "Multicolor", gp1: "Warm", gp2: "Cool", gp3: "Theme",
        gBright: "Brightness", gSpeed: "Animation speed", gSize: "Bulb size",
        interactive: "Interactive zones", interactiveHint: "snowballs, snowmen, mouse sweeping",
        dance: "Dance to music", danceHint: "snowmen dance when music plays",
        game: "Game mode", gameHint: "hide snow in games and fullscreen windows",
        advanced: "Advanced",
        wind: "Wind", windDir: "Direction and strength", gusts: "Wind gusts", gustsHint: "wind strength sways on its own",
        accum: "Accumulation", accumOn: "Snow buildup", accumHint: "master switch for snow piles",
        bottom: "Snow at screen bottom", onWin: "Snow on windows",
        growTime: "Pile growth time", secUnit: " s", maxWin: "Max snow on windows", maxBottom: "Max bottom pile",
        snowmen: "Snowmen", build: "Build snowmen", buildHint: "put a smaller ball on a bigger one",
        announce: "Announce rare ones", announceHint: "banner and confetti on appearance",
        balls: "Snowballs and sweeping", ballGrow: "Ball growth speed", ballMax: "Max ball size", brush: "Sweep width",
        react: "Snowmen vs. vehicle", r0: "Sweeps all", r1: "Rare hop", r2: "All hop",
        reactHint: "What happens to snowmen and balls when the vehicle drives by. Common ones crumble; in 'Rare hop' mode rare ones and above jump over the blade.",
        perf: "Performance", save: "Power saver", saveHint: "fewer flakes and effects, slower updates",
        actions: "Actions", melt: "Melt snowmen", pop: "Pop snowballs",
        reset: "Reset", resetBtn: "Reset settings", resetSure: "Sure? Click again",
        resetHint: "Restores defaults. Your snowman collection is kept.",
        how: "How to use",
        h1: "• Hover over a snow cap on a window to sweep it away.",
        h2: "• Right-click on snow (window or screen bottom) to make a snowball. Hold to grow it.",
        h3: "• Put a smaller ball on a bigger one to get a snowman. Which one? Luck decides.",
        h4: "• Drag a snowman anywhere with the left button.",
        collection: "Snowman collection", collHint: "Click an unlocked card to summon that snowman.",
        found: "found", notFound: "not found yet",
        tier0: "Common", tier1: "Uncommon", tier2: "Rare", tier3: "Epic", tier4: "Legendary", tier5: "Mythic",
        sm_classic: "Classic", sm_cozy: "Cozy", sm_gent: "Gentleman", sm_pirate: "Pirate", sm_ninja: "Ninja",
        sm_cowboy: "Cowboy", sm_king: "King", sm_santa: "Santa", sm_astro: "Astronaut", sm_frost: "Frost Spirit"
    })

    readonly property var uk: ({
        sub: "сніг, сніговики й різдвяна фура",
        clear: "Прибрати сніг", send: "Виїзд техніки",
        tabSettings: "Налаштування", tabCollection: "Колекція",
        level: "Рівень снігу", lvl0: "Вимк.", lvl1: "Легкий", lvl2: "Помірний", lvl3: "Сильний", lvl4: "Змінний",
        snowOpacity: "Прозорість снігу",
        presets: "Пресети", pCozy: "Затишний", pStorm: "Завірюха", pMin: "Мінімум",
        transport: "Транспорт", vTruck: "Вантажівка", vSleigh: "Сани", vRandom: "Випадково",
        vehOpacity: "Прозорість техніки", truckSize: "Розмір вантажівки",
        theme: "Колір теми", language: "Мова",
        modes: "Режими",
        garland: "Гірлянди", garlandOn: "Показувати гірлянди", garlandOnHint: "різдвяні вогники по екрану",
        gTop: "Верх екрана", gTopHint: "дуги під верхньою панеллю",
        gWin: "Верхні краї вікон", gWinHint: "вогники на снігових шапках",
        gIce: "Бурульки з вікон", gIceHint: "звисають з країв вікон",
        gFrame: "Рамка екрана", gFrameHint: "одна петля по всьому екрану",
        gGround: "На снігу", gGroundHint: "лежать уздовж купи знизу",
        gMan: "На сніговиках", gManHint: "гірлянда навколо кожного сніговика",
        gMode: "Анімація", gm0: "Рівно", gm1: "Блимання", gm2: "Хвиля", gm3: "Музика",
        gModeHint: "Музика: вогники спалахують у такт (потрібен cava; без нього — рівний темп 120 уд./хв), а так світяться м'яко.",
        gPal: "Кольори", gp0: "Різнокольорові", gp1: "Теплі", gp2: "Холодні", gp3: "Під тему",
        gBright: "Яскравість", gSpeed: "Швидкість анімації", gSize: "Розмір лампочок",
        interactive: "Інтерактивні зони", interactiveHint: "кульки, сніговики, змітання мишею",
        dance: "Танці під музику", danceHint: "сніговики танцюють, коли грає музика",
        game: "Режим ігор", gameHint: "ховати сніг, коли гра або вікно на весь екран",
        advanced: "Додатково",
        wind: "Вітер", windDir: "Напрямок і сила", gusts: "Пориви вітру", gustsHint: "сила вітру хитається сама",
        accum: "Накопичення", accumOn: "Накопичення снігу", accumHint: "головний вимикач сугробів",
        bottom: "Сніг унизу екрана", onWin: "Сніг на вікнах",
        growTime: "Час росту сугробу", secUnit: " с", maxWin: "Макс. сніг на вікнах", maxBottom: "Макс. купа знизу",
        snowmen: "Сніговики", build: "Складати сніговиків", buildHint: "постав меншу кульку на більшу",
        announce: "Оголошувати рідкісних", announceHint: "банер і конфеті при появі",
        balls: "Кульки та змітання", ballGrow: "Швидкість росту кульки", ballMax: "Макс. розмір кульки", brush: "Ширина змітання",
        react: "Реакція сніговиків", r0: "Зносить усіх", r1: "Рідкісні стрибають", r2: "Усі стрибають",
        reactHint: "Що буде зі сніговиками й кульками, коли їде техніка. Звичайні розсипаються, а в режимі «Рідкісні стрибають» рідкісні й вище перестрибують лезо.",
        perf: "Продуктивність", save: "Економія ресурсів", saveHint: "менше сніжинок і ефектів, рідші оновлення",
        actions: "Дії", melt: "Розтопити сніговиків", pop: "Розсипати кульки",
        reset: "Скидання", resetBtn: "Скинути налаштування", resetSure: "Точно скинути? Натисни ще раз",
        resetHint: "Повертає значення за замовчуванням. Колекція сніговиків не чіпається.",
        how: "Як користуватись",
        h1: "• Води курсором по замету на вікні — змітаєш сніг.",
        h2: "• Права кнопка на снігу (вікно або низ екрана) — ліпиш кульку. Тримай, щоб росла.",
        h3: "• Постав меншу кульку на більшу — вийде сніговик, а який саме, вирішує випадок.",
        h4: "• Лівою кнопкою можна взяти сніговика й перенести куди завгодно.",
        collection: "Колекція сніговиків", collHint: "Натисни на відкриту картку, щоб викликати цього сніговика.",
        found: "знайдено", notFound: "ще не знайдено"
    })
    readonly property color accent: palette[Math.max(0, Math.min(palette.length - 1, accentIdx))]

    FileView {
        path: root.dir + "/config.json"
        watchChanges: true
        onFileChanged: reload()
        adapter: JsonAdapter {
            id: adapter
            property int level: 2
            property bool accumulate: true
            property bool melt: false
            property bool bottom: true
            property bool bottomAuto: false
            property real bottomOffset: 0
            property real bottomMax: 36
            property bool windowSnow: true
            property real windowMax: 26
            property real growSeconds: 60
            property int clearTick: 0
            property int tractorTick: 0
            property real windStrength: 0
            property bool windGust: false
            property real brushSize: 40
            property real ballGrow: 1
            property real ballMax: 48
            property real luck: 0
            property bool snowmenOn: true
            property bool announce: true
            property string foundJson: "{}"
            property int tractorMode: 1
            property int vehicle: 3
            property bool paused: false
            property bool gameMode: true
            property bool saveMode: false
            property bool dance: true
            property bool interactive: true
            property real vehicleOpacity: 0.85
            property real vehicleScale: 0.55
            property real snowOpacity: 1
            property int accentIdx: 0
            property string lang: "auto"
            property bool garland: true
            property bool garlandTop: true
            property bool garlandWin: true
            property bool garlandIce: false
            property bool garlandFrame: false
            property bool garlandGround: false
            property bool garlandMan: false
            property int garlandMode: 2
            property int garlandPalette: 0
            property real garlandBright: 1
            property real garlandSpeed: 1
            property real garlandSize: 1
        }
    }
}
