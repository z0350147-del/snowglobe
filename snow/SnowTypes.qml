pragma Singleton
import QtQuick

QtObject {
    readonly property var tiers: [
        { name: "Звичайний", color: "#9fb3c8" },
        { name: "Незвичайний", color: "#4ade80" },
        { name: "Рідкісний", color: "#38bdf8" },
        { name: "Епічний", color: "#c084fc" },
        { name: "Міфічний", color: "#fb923c" },
        { name: "Легендарний", color: "#fde047" }
    ]

    readonly property var list: [
        { id: 0, key: "classic", name: "Класичний", tier: 0, weight: 30, hatK: 0.5,
          body: "#f6faff", edge: "#b8cde6", hat: "#3f7fd0", pom: "#f6faff", scarf: "#d9433f",
          arm: "#6b472b", cheek: "#ff9bb0", buttons: ["#d9433f", "#f2b632", "#3f7fd0"] },
        { id: 1, key: "cozy", name: "Затишний", tier: 0, weight: 20, hatK: 0.5,
          body: "#f8fbff", edge: "#c3d2e6", hat: "#d9433f", pom: "#ffffff", scarf: "#2f9e5f",
          arm: "#6b472b", cheek: "#ff8fa3", buttons: ["#f2b632", "#f2b632", "#f2b632"] },
        { id: 2, key: "gent", name: "Джентльмен", tier: 1, weight: 14, hatK: 0.66,
          body: "#f6faff", edge: "#b8cde6", hat: "#20242d", pom: "#ffffff", scarf: "#d9433f",
          arm: "#4a3220", cheek: "#ffb0bf", buttons: ["#20242d", "#20242d", "#20242d"] },
        { id: 3, key: "pirate", name: "Пірат", tier: 1, weight: 10, hatK: 0.42,
          body: "#f4f8fd", edge: "#b4c6dd", hat: "#b3202a", pom: "#ffffff", scarf: "#b3202a",
          arm: "#5b3d26", cheek: "#ff9bb0", buttons: ["#f2c230", "#f2c230", "#f2c230"] },
        { id: 4, key: "ninja", name: "Ніндзя", tier: 2, weight: 8, hatK: 0.36,
          body: "#f1f6fc", edge: "#aebfd6", hat: "#1b1f27", pom: "#ffffff", scarf: "#3a3f4b",
          arm: "#2b2f3a", cheek: "#ff9bb0", buttons: [] },
        { id: 5, key: "cowboy", name: "Ковбой", tier: 2, weight: 6, hatK: 0.5,
          body: "#f8f6f0", edge: "#cdbfa5", hat: "#8b5a2b", pom: "#ffffff", scarf: "#c0392b",
          arm: "#6b472b", cheek: "#ffa28a", buttons: [] },
        { id: 6, key: "king", name: "Король", tier: 3, weight: 5, hatK: 0.58,
          body: "#fbfcff", edge: "#c9d3ee", hat: "#f2c230", pom: "#ffffff", scarf: "#ffffff",
          arm: "#8a6a2b", cheek: "#ffa6b5", buttons: ["#f2c230", "#f2c230", "#f2c230"] },
        { id: 7, key: "santa", name: "Дід Мороз", tier: 3, weight: 4, hatK: 0.66,
          body: "#fdfdff", edge: "#d3dcef", hat: "#d62828", pom: "#ffffff", scarf: "#ffffff",
          arm: "#8b1e1e", cheek: "#ff7d8a", buttons: [] },
        { id: 8, key: "astro", name: "Космонавт", tier: 4, weight: 2, hatK: 0.64,
          body: "#f3f8ff", edge: "#a9c2e3", hat: "#9aa7b8", pom: "#ffffff", scarf: "#9aa7b8",
          arm: "#aab6c6", cheek: "#ff9bb0", buttons: ["#38bdf8", "#f87171", "#4ade80"] },
        { id: 9, key: "frost", name: "Дух Зими", tier: 5, weight: 1, hatK: 0.72,
          body: "#eaf8ff", edge: "#9fdcff", hat: "#bfeaff", pom: "#ffffff", scarf: "#9fdcff",
          arm: "#9fdcff", cheek: "#b9a8ff", buttons: ["#bfeaff", "#e0c3ff", "#bfeaff"] }
    ]

    function roll(luck) {
        var l = Math.max(0, luck || 0);
        var ws = [];
        var sum = 0;
        for (var i = 0; i < list.length; i++) {
            var w = list[i].weight * Math.pow(1 + 0.5 * l, list[i].tier);
            ws.push(w);
            sum += w;
        }
        var r = Math.random() * sum;
        for (var j = 0; j < ws.length; j++) {
            r -= ws[j];
            if (r <= 0) return j;
        }
        return 0;
    }
}
