/// <reference path="../pb_data/types.d.ts" />

// charts: 서버에 업로드된 채보(곡) 메타데이터 + 파일
// scores: 유저별 채보/난이도별 최고 기록 (기존 클라이언트 play_data.cfg에 대응)
migrate((app) => {
  const charts = new Collection({
    type: "base",
    name: "charts",
    listRule: "",
    viewRule: "",
    createRule: null,
    updateRule: null,
    deleteRule: null,
    fields: [
      { name: "chart_key", type: "text", required: true },
      { name: "song_name", type: "text", required: true },
      { name: "artist", type: "text" },
      { name: "difficulty_levels", type: "json" },
      { name: "length_ms", type: "number" },
      { name: "music_file", type: "file", maxSelect: 1, maxSize: 20000000 },
      { name: "easy_chart", type: "file", maxSelect: 1, maxSize: 5000000 },
      { name: "hard_chart", type: "file", maxSelect: 1, maxSize: 5000000 },
      { name: "vex_chart", type: "file", maxSelect: 1, maxSize: 5000000 },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_charts_chart_key ON charts (chart_key)",
    ],
  });
  app.save(charts);

  const users = app.findCollectionByNameOrId("users");

  const scores = new Collection({
    type: "base",
    name: "scores",
    listRule: "@request.auth.id != \"\"",
    viewRule: "@request.auth.id != \"\"",
    createRule: "@request.auth.id != \"\" && @request.auth.id = user",
    updateRule: "@request.auth.id != \"\" && @request.auth.id = user",
    deleteRule: null,
    fields: [
      { name: "user", type: "relation", required: true, collectionId: users.id, maxSelect: 1 },
      { name: "chart", type: "relation", required: true, collectionId: charts.id, maxSelect: 1 },
      { name: "difficulty", type: "number", required: true },
      { name: "best_score", type: "number" },
      { name: "vexatonic_count", type: "number" },
      { name: "combo_lamp", type: "number" },
      { name: "paint_lamp", type: "bool" },
      { name: "rank", type: "number" },
      { name: "best_paint_ratio", type: "number" },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_scores_user_chart_diff ON scores (user, chart, difficulty)",
    ],
  });
  app.save(scores);
}, (app) => {
  app.delete(app.findCollectionByNameOrId("scores"));
  app.delete(app.findCollectionByNameOrId("charts"));
});
