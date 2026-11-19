class_name JsonResponseParser
extends RefCounted
## Parses JSON payloads from HTTP responses without crashing on malformed input.


static func parse_http_response(response: Variant, safe := true) -> Variant:
	var response_body := response[3] as PackedByteArray
	var response_text := response_body.get_string_from_utf8()
	if safe:
		return parse_safely(response_text)
	return JSON.parse_string(response_text)


static func parse_safely(json_text: String) -> Variant:
	var json := JSON.new()
	if json.parse(json_text) != OK:
		return null
	return json.data
