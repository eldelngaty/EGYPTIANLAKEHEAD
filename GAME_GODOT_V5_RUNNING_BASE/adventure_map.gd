extends Control
var current_location := "agora"
func _draw() -> void:
    var font:=ThemeDB.fallback_font
    var points: Dictionary={"agora":Vector2(95,58),"corridor":Vector2(548,58),"atac":Vector2(548,160),"lake":Vector2(95,160)}
    var names: Dictionary={"agora":"Agora Circle","corridor":"Library Approach","atac":"ATAC","lake":"Lake Tamblyn"}
    var centre:=Vector2(330,110)
    for id in points:
        var at: Vector2=points[id]
        draw_line(centre,at,Color("3c6775"),2,true)
        draw_circle(at,22,Color("4a6472") if id!=current_location else Color("c7a45d"))
        draw_arc(at,26,0,TAU,48,Color("78c5d6"),2,true)
        draw_string(font,at+Vector2(-67,-34),names[id],HORIZONTAL_ALIGNMENT_CENTER,140,17,Color("e7edef"))
    draw_circle(centre,29,Color("183544"))
    draw_string(font,centre+Vector2(-65,-3),"THUNDER BAY",HORIZONTAL_ALIGNMENT_CENTER,130,13,Color("a7d9e0"))
    draw_string(font,centre+Vector2(-65,14),"OFFICIAL TOUR",HORIZONTAL_ALIGNMENT_CENTER,130,11,Color("96b7c4"))
    draw_string(font,Vector2(15,207),"Nefertiti → Lake Tamblyn     •     Location diagram, not to scale",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("f0cb78"))
