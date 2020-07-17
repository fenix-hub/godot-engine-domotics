extends Control

var menu : bool = true #the switch sets it false
onready var debug_web : Node = $Debug
onready var status1 : Node = $DeviceChoice/VBoxContainer/HBoxContainer/status2
onready var status2 : Node = $DeviceManager/VBoxContainer2/HBoxContainer/status
var Animator : Tween = Tween.new()
onready var Menu : Control = $Menu
onready var Filter : Control = $Filter

func _ready() -> void:
    add_child(Animator)
    HTTPManager.connect("update_status_signal",self,"update_status")
    
    webserver_data.load_data(webserver_data.data_file)
    switch_child($DeviceChoice)
    $DeviceChoice/VBoxContainer/HBoxContainer2/disconnect.disabled = true
    webserver_data.webserver_state = "disconnected"
    update_status(webserver_data.webserver_state)
    
    

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func manage_menu() -> void:
    menu=!menu
    Filter.set_visible(menu)
    var new_pos : Vector2
    match (menu):
        false:
            new_pos = Vector2(-459.514,0)
        true:
            new_pos = Vector2(0,0)
            
    Animator.interpolate_property(Menu,"rect_position",Menu.get_position(),new_pos,0.3,Tween.TRANS_QUAD,Tween.EASE_OUT)
    Animator.interpolate_property(Filter,"modulate",Filter.get_modulate(),Color(1,1,1,float(menu)),0.3,Tween.TRANS_QUAD,Tween.EASE_OUT)
    Animator.start()

func _on_MenuButton_pressed():
    manage_menu()

func switch_child(child : Node) -> void:
    for ch in get_children():
        if ch.get_class()=="Control" and ch.get_name() != "Overlay" and ch.get_name() != "Menu":
            if  ch != child :
                ch.visible=false
            else:
                ch.visible=true



func _on_Webserver_pressed():
    switch_child($DeviceManager)
    manage_menu()


func _on_ChangeIP_pressed():
    switch_child($DeviceChoice)
    manage_menu()


func _on_Exit_pressed():
    get_tree().set_auto_accept_quit(false)
    get_tree().quit()

func _on_disconnect_pressed():
    
    webserver_data.webserver_state = "disconnected"
    update_status(webserver_data.webserver_state)
    HTTPManager.Request.cancel_request()
    $DeviceChoice/VBoxContainer/HBoxContainer2/connect.disabled = false
    $DeviceChoice/VBoxContainer/HBoxContainer2/disconnect.disabled = true


func _on_connect_pressed():
    var ip : String = $DeviceChoice/VBoxContainer/webserver_ip.get_text()
    var nam : String = $DeviceChoice/VBoxContainer/webserver_name.get_text()
    if ip!="" and nam!="":
        webserver_data.webserver_state = "pending"
        
        update_status(webserver_data.webserver_state)
        
        $DeviceChoice/VBoxContainer/HBoxContainer2/connect.disabled = true
        $DeviceChoice/VBoxContainer/HBoxContainer2/disconnect.disabled = false
        webserver_data.current_webserver(ip,nam)
        
        webserver_data.save_data(webserver_data.data_file,"")
        
        $DeviceManager/VBoxContainer2/HBoxContainer/w_ip.set_text(ip)
        $DeviceManager/VBoxContainer2/HBoxContainer/w_name.set_text(nam)
        
        HTTPManager.httprequest("request","",HTTPManager.RequestHandlers[0])


func _on_WebserverList_pressed():
    switch_child($WebServerList)
    $WebServerList/Tree.load_webserver_list()
    manage_menu()

func _on_Guide_pressed():
    switch_child($Guide)
    manage_menu()

func _on_Debug_pressed():
    switch_child(debug_web)
    manage_menu()

func _on_Tree_item_selected():
    var webserver : TreeItem = $WebServerList/Tree.get_selected()
    $DeviceChoice/VBoxContainer/webserver_ip.set_text(webserver.get_text(0))
    $DeviceChoice/VBoxContainer/webserver_name.set_text(webserver.get_text(1))
    switch_child($DeviceChoice)

func _on_Log_pressed():
    switch_child($Log)
    manage_menu()

func update_status(http_r : String) -> void:
    match(http_r):
        "connected":
            debug_web.debug_print("Connesso al server","green")
            HTTPManager.emit_signal("log_signal","Connesso al server")
            $DeviceChoice/VBoxContainer/state_message.text = "Connected to Webserver!"
        "error":
            debug_web.debug_print("Errore nella connessione","red")
            $DeviceChoice/VBoxContainer/state_message.text = "Can't connect to Webserver!"
            HTTPManager.emit_signal("log_signal","Errore nella connessione")
            _on_disconnect_pressed()
        "disconnected":
            debug_web.debug_print("Disconnesso dal server","gray")
            $DeviceChoice/VBoxContainer/state_message.text = "No webserver to connect to."
            HTTPManager.emit_signal("log_signal","Disconnesso dal server")
        "pending":
            debug_web.debug_print("Provo a connettermi al server...","orange")
            $DeviceChoice/VBoxContainer/state_message.text = "Connecting to the webserver..."
            HTTPManager.emit_signal("log_signal","Provo a connettermi al server...")
        _:
            http_r = "error"
            debug_web.debug_print("Errore nella connessione","red")
            $DeviceChoice/VBoxContainer/state_message.text = "Can't connect to Webserver!"
            HTTPManager.emit_signal("log_signal","Errore nella connessione")
            _on_disconnect_pressed()
    status1.match_icon_status(str(http_r))
    status2.match_icon_status(str(http_r))


func _on_moisture_btn_toggled(button_pressed):
    if (button_pressed):
        $DeviceManager/VBoxContainer2/VBoxContainer/HBoxContainer2/moisture/Timer2.start()
        debug_web.debug_print("Attivato aggiornamento umidità","cyan")
    else:
        $DeviceManager/VBoxContainer2/VBoxContainer/HBoxContainer2/moisture/Timer2.stop()
        $DeviceManager/VBoxContainer2/VBoxContainer/HBoxContainer2/moisture.text = "---"
        HTTPManager.Request.cancel_request()
        debug_web.debug_print("Disattivato aggiornamento umidità","gray")

func _on_led1_toggled(button_pressed):
    HTTPManager.httprequest("command","output1",HTTPManager.RequestHandlers[0])

#func _on_HTTPCommand_request_completed(result, response_code, headers, body):
#	HTTPManager.httprequest("moisture")




func _on_ColorPicker_color_changed(color : Color):
    print(color.to_html());
    HTTPManager.httprequest("command","color",HTTPManager.RequestHandlers[0],
    {
     "r":str(color.r8),    
     "g":str(color.g8),    
     "b":str(color.b8),    
    })
