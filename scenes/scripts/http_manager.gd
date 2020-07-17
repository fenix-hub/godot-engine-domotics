extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

signal debug_signal(message,color) 
signal update_status_signal(status)
signal update_moisture(val)
signal log_signal(message)

onready var Request : HTTPRequest = $HTTPRequest
onready var TimedRequest : HTTPRequest = $TimedHTTPRequest
onready var Command : Node = $HTTPCommand

var RequestHandlers = []

var body_request : String = ""

# Called when the node enters the scene tree for the first time.
func _ready():
     RequestHandlers = [ Request, TimedRequest ]

func httprequest(type : String, body_r : String, request_handler : HTTPRequest , requestBody : Dictionary = {}) -> void:
    if webserver_data.webserver_state == "connected" or webserver_data.webserver_state == "pending":
        var http_request : String = webserver_data.webserver_ip+"/"+body_r
        body_request = body_r
        emit_signal("debug_signal","Richiesta http: " + str(http_request) + " (tipo: "+type+")","green")
        var err : int
        match(type):
            "request":
                err = request_handler.request("http://"+http_request,["Cache-Control: no-cache"],false,0,"")
                
            "command":
                Command.cancel_request()
                match(body_r):
                    "toggleled1":
                        emit_signal("debug_signal","Accensione/Spegnimento Led1","arancione")
                    "colore":
                        emit_signal("debug_signal","Cambio colore","arancione")
                err = Command.request("http://"+http_request,["Cache-Control: no-cache"],false,0,JSON.print(requestBody))
                
        emit_signal("debug_signal","Risposta http: " + str(err),"yellow")
        if err > 1:
            webserver_data.webserver_state = "error"
            emit_signal("update_status_signal",(webserver_data.webserver_state))
    else:
        emit_signal("debug_signal","Disconnesso dal Webserver, impossibile eseguire richieste","red")

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
    if webserver_data.webserver_state == "connected" or webserver_data.webserver_state == "pending":
        emit_signal("debug_signal","Richiesta http eseguita...","green")
        emit_signal("debug_signal","Result code to http request: "+str(result),"yellow")
        emit_signal("debug_signal","Response code to http request: "+str(response_code),"yellow")
        
        var http_response = str(body.get_string_from_utf8())
        print(http_response)
        Request.cancel_request()
        
        if body_request == "":
            emit_signal("update_status_signal",http_response)
            webserver_data.webserver_state = http_response
            
        else:
            emit_signal("update_moisture",str(http_response))
            
            emit_signal("log_signal","Moisture = "+http_response)
            
            emit_signal("debug_signal","Aggiorno umidità: "+http_response,"orange")
    else:
        emit_signal("debug_signal","Disconnesso dal Webserver, impossibile completare richieste","red")

