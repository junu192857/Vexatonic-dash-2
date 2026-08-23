extends Node

# PocketBase 서버 REST API 클라이언트 (실시간 통신 없음, 요청/응답 방식)

const DEFAULT_BASE_URL = "http://127.0.0.1:8090"
const AUTH_SAVE_PATH = "user://server_auth.cfg"

var base_url: String = DEFAULT_BASE_URL
var auth_token: String = ""
var user_id: String = ""
var user_email: String = ""

func _ready() -> void:
	load_auth()

func is_logged_in() -> bool:
	return auth_token != ""

func register(email: String, password: String, display_name: String = "") -> Dictionary:
	var body := {"email": email, "password": password, "passwordConfirm": password}
	if display_name != "":
		body["name"] = display_name
	return await _request(HTTPClient.METHOD_POST, "/api/collections/users/records", body)

func login(email: String, password: String) -> Dictionary:
	var body := {"identity": email, "password": password}
	var res := await _request(HTTPClient.METHOD_POST, "/api/collections/users/auth-with-password", body)
	if res["ok"]:
		auth_token = res["data"]["token"]
		user_id = res["data"]["record"]["id"]
		user_email = res["data"]["record"].get("email", email)
		save_auth()
	return res

func logout() -> void:
	auth_token = ""
	user_id = ""
	user_email = ""
	save_auth()

func list_charts() -> Dictionary:
	return await _request(HTTPClient.METHOD_GET, "/api/collections/charts/records?perPage=200")

func submit_score(chart_id: String, difficulty: int, best_score: int, vexatonic_count: int, combo_lamp: int, paint_lamp: bool, rank: int, best_paint_ratio: float) -> Dictionary:
	if not is_logged_in():
		return {"ok": false, "status": 0, "error": "not_logged_in"}
	var body := {
		"user": user_id,
		"chart": chart_id,
		"difficulty": difficulty,
		"best_score": best_score,
		"vexatonic_count": vexatonic_count,
		"combo_lamp": combo_lamp,
		"paint_lamp": paint_lamp,
		"rank": rank,
		"best_paint_ratio": best_paint_ratio,
	}
	return await _request(HTTPClient.METHOD_POST, "/api/collections/scores/records", body, true)

# 이미 이 유저의 (chart, difficulty) 기록이 있으면 record id를 돌려주고, submit_score는 update로 대체해야 함
func get_my_score(chart_id: String, difficulty: int) -> Dictionary:
	if not is_logged_in():
		return {"ok": false, "status": 0, "error": "not_logged_in"}
	var filter := "user=\"%s\" && chart=\"%s\" && difficulty=%d" % [user_id, chart_id, difficulty]
	return await _request(HTTPClient.METHOD_GET, "/api/collections/scores/records?filter=%s" % filter.uri_encode(), {}, true)

func update_score(record_id: String, best_score: int, vexatonic_count: int, combo_lamp: int, paint_lamp: bool, rank: int, best_paint_ratio: float) -> Dictionary:
	if not is_logged_in():
		return {"ok": false, "status": 0, "error": "not_logged_in"}
	var body := {
		"best_score": best_score,
		"vexatonic_count": vexatonic_count,
		"combo_lamp": combo_lamp,
		"paint_lamp": paint_lamp,
		"rank": rank,
		"best_paint_ratio": best_paint_ratio,
	}
	return await _request(HTTPClient.METHOD_PATCH, "/api/collections/scores/records/%s" % record_id, body, true)

# chart_record: list_charts()로 받은 charts 레코드 하나. field: "music_file"/"easy_chart"/"hard_chart"/"vex_chart"
func download_chart_file(chart_record: Dictionary, field: String, save_path: String) -> Dictionary:
	var file_name: String = chart_record.get(field, "")
	if file_name == "":
		return {"ok": false, "status": 0, "error": "no_file"}
	var url := "%s/api/files/%s/%s/%s" % [base_url, chart_record["collectionId"], chart_record["id"], file_name]
	var http := HTTPRequest.new()
	add_child(http)
	http.download_file = save_path
	var err := http.request(url)
	if err != OK:
		http.queue_free()
		return {"ok": false, "status": 0, "error": "request_failed"}
	var result: Array = await http.request_completed
	http.queue_free()
	var response_code: int = result[1]
	return {"ok": response_code >= 200 and response_code < 300, "status": response_code}

func save_auth() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("auth", "token", auth_token)
	cfg.set_value("auth", "user_id", user_id)
	cfg.set_value("auth", "user_email", user_email)
	cfg.save(AUTH_SAVE_PATH)

func load_auth() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(AUTH_SAVE_PATH) != OK:
		return
	auth_token = cfg.get_value("auth", "token", "")
	user_id = cfg.get_value("auth", "user_id", "")
	user_email = cfg.get_value("auth", "user_email", "")

# result: {"ok": bool, "status": int, "data": Variant}
func _request(method: HTTPClient.Method, path: String, body: Dictionary = {}, authorized: bool = false) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)
	var headers := PackedStringArray(["Content-Type: application/json"])
	if authorized and auth_token != "":
		headers.append("Authorization: %s" % auth_token)
	var body_str := JSON.stringify(body) if not body.is_empty() else ""
	var err := http.request(base_url + path, headers, method, body_str)
	if err != OK:
		http.queue_free()
		return {"ok": false, "status": 0, "error": "request_failed"}
	var result: Array = await http.request_completed
	http.queue_free()
	var response_code: int = result[1]
	var response_body: PackedByteArray = result[3]
	var text := response_body.get_string_from_utf8()
	var parsed = JSON.parse_string(text) if text != "" else null
	return {
		"ok": response_code >= 200 and response_code < 300,
		"status": response_code,
		"data": parsed,
	}
