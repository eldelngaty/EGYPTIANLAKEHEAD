extends Control
var age := 0.0
var duration := .9
func _ready() -> void:
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _process(delta: float) -> void:
    age+=delta
    queue_redraw()
    if age>duration: queue_free()
func _draw() -> void:
    var alpha:=sin(clampf(age/duration,0,1)*PI)*.75
    var center:=size*.5
    var radius:=72.0+age*160
    var color:=Color(1.0,.79,.35,alpha)
    draw_arc(center,radius,0,TAU,80,color,2,true)
    for i in range(8):
        var angle:=TAU*i/8+age*.4
        var at:=center+Vector2(cos(angle),sin(angle))*radius
        draw_arc(at+Vector2(0,-9),7,0,TAU,16,color,2,true)
        draw_line(at+Vector2(0,-2),at+Vector2(0,18),color,2,true)
        draw_line(at+Vector2(-8,6),at+Vector2(8,6),color,2,true)
