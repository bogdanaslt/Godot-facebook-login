extends Control

const HOST = 'graph.facebook.com'
const APP_ID_CLIENT_TOKEN = "1235481099845454|57a4e8e724d61bae0b3bb532e184b987"

var token
var client
var config
var resp = {}
var headers = [ "Accept:*/*", "Content-Type:application/x-www-form-urlencoded; charset=UTF-8", "User-Agent: Godot / 2.1"]
var data = {
	"access_token" : APP_ID_CLIENT_TOKEN,
	"scope": "public_profile"
}

onready var popup = get_node("info_dialog")

func _ready():
	config = ConfigFile.new()
	config.load("res://config.ini")
	client = HTTPClient.new()
	client.connect(HOST, 443, true, false)
	while client.get_status() == HTTPClient.STATUS_CONNECTING or client.get_status() == HTTPClient.STATUS_RESOLVING:
		client.poll()
		OS.delay_usec(500)

func _on_login_pressed():
	token = config.get_value("Facebook", "access_token")
	if not token:
		var query = client.query_string_from_dict(data)
		var result = client.request(client.METHOD_POST, "/v2.6/device/login", headers, query)
		resp.parse_json(get_client_data().get_string_from_ascii())
		popup.get_node("code").set_text(resp.user_code)
		popup.get_node("link").set_text("Go to %s and enter code displayed below" % resp.verification_uri)
		popup.show()
	else:
		get_facebook_user()

func _on_info_dialog_confirmed():
	var query = client.query_string_from_dict({"access_token" : APP_ID_CLIENT_TOKEN, "code": resp.code})
	var result = client.request(client.METHOD_POST, "/v2.6/device/login_status", headers, query)
	var response = {}
	response.parse_json(get_client_data().get_string_from_ascii())
	if not response.has("access_token"):
		popup.show()
	else:
		token = response.access_token
		config.set_value("Facebook", "access_token", token)
		config.save("res://config.ini")
		get_facebook_user()

func get_client_data():
	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		client.poll()
		OS.delay_usec(500)
	var rb = RawArray()
	while client.get_status()==HTTPClient.STATUS_BODY:
		client.poll()
		var chunk = client.read_response_body_chunk()
		if chunk.size() == 0:
			OS.delay_usec(1000)
		else:
			rb = rb + chunk
	return rb

func get_facebook_user():
	var result = client.request(client.METHOD_GET, "/v2.6/me?access_token=" + token, headers)
	var user = {}
	user.parse_json(get_client_data().get_string_from_ascii())
	get_node("user_name").set_text(user.id + ":" + user.name)