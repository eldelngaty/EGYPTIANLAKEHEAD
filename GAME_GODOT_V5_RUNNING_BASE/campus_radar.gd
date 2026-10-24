extends Control
var game: Node
var full := false
func _draw() -> void:
    var bounds:=Rect2(Vector2.ZERO,size)
    draw_style_box(style(),bounds)
    var scale_factor:=Vector2((size.x-24)/120,(size.y-45)/96)
    var origin:=Vector2(12,30)
    for b in [Rect2(-19,-18,18,12),Rect2(12,4.5,18,13),Rect2(29.5,-19.5,17,13)]:
        draw_rect(Rect2(origin+(b.position+Vector2(60,48))*scale_factor,b.size*scale_factor),Color("657681"))
    for path in [[Vector2(-22,-25),Vector2(26,-25)],[Vector2(12,-25),Vector2(12,0)],[Vector2(-18,0),Vector2(49,0)],[Vector2(-18,0),Vector2(-18,20)],[Vector2(-18,20),Vector2(-46,20)]]:
        draw_line(origin+(path[0]+Vector2(60,48))*scale_factor,origin+(path[1]+Vector2(60,48))*scale_factor,Color("c4bba0"),3)
    draw_circle(origin+Vector2(28,68)*scale_factor,12*scale_factor.x,Color("315a70"))
    if game==null:return
    var target:Vector3=game.adventure.target()
    draw_circle(origin+(Vector2(target.x,target.z)+Vector2(60,48))*scale_factor,6,Color("ffcf65"))
    var at:=origin+(Vector2(game.player.position.x,game.player.position.z)+Vector2(60,48))*scale_factor
    var direction:=Vector2(sin(game.player_model.rotation.y),cos(game.player_model.rotation.y))
    draw_colored_polygon(PackedVector2Array([at+direction*8,at-direction*5+direction.orthogonal()*5,at-direction*5-direction.orthogonal()*5]),Color("9ce9ec"))
    draw_string(ThemeDB.fallback_font,Vector2(12,20),"CAMPUS / N ↑" if not full else "MISSION MAP / COMPACT CAMPUS MODEL",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("e9d7ab"))
    if full:
        for label in [["AGORA",Vector2(-10,-12)],["LIBRARY",Vector2(21,11)],["ATAC",Vector2(38,-13)],["LAKE TAMBLYN",Vector2(-32,33)]]:
            draw_string(ThemeDB.fallback_font,origin+(label[1]+Vector2(60,48))*scale_factor+Vector2(-25,0),label[0],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
        if game.map_found:
            draw_string(ThemeDB.fallback_font,origin+Vector2(14,68)*scale_factor+Vector2(0,-14),"NEFERTITI",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("ffcf65"))
func style() -> StyleBoxFlat:
    var s:=StyleBoxFlat.new()
    s.bg_color=Color("101f2eeb")
    s.border_color=Color("b69955")
    s.set_border_width_all(1)
    s.set_corner_radius_all(12)
    return s
