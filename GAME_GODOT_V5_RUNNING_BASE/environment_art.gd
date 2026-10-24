extends RefCounted
# Modular campus art; quest state remains in main.gd.
var materials: Dictionary = {}
var limbs: Array[Node3D] = []
var phase := 0.0

func material(key: String, color: Color, roughness := 0.8, metallic := 0.0) -> StandardMaterial3D:
    if materials.has(key):
        return materials[key]
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = roughness
    m.metallic = metallic
    if key in ["brick", "concrete", "paving"]:
        m.albedo_texture = load("res://assets/art_" + key + ".png")
        m.uv1_triplanar = true
        m.uv1_scale = Vector3.ONE * (0.6 if key == "brick" else 0.3)
        m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    materials[key] = m
    return m

func block(g: Node, p: Node3D, at: Vector3, size: Vector3, mat: Material, solid := false) -> Node3D:
    var n: Node3D = g._box(p, at, size, Color.WHITE, solid)
    n.get_child(0).material_override = mat
    return n

func window(g: Node, at: Vector3, size: Vector2, variation: int) -> void:
    var frame := material("frame", Color("283e47"), .35, .6)
    var glass := material("glass%d" % (variation % 4), [Color("3e6c80"),Color("547f90"),Color("355e77"),Color("658b9d")][variation % 4], .18, .65)
    block(g,g,at,Vector3(size.x+.14,size.y+.14,.19),frame)
    block(g,g,at+Vector3(0,0,-.115),Vector3(size.x,size.y,.06),glass)
    block(g,g,at+Vector3(0,0,-.16),Vector3(.055,size.y,.07),frame)
    # Slim upper reflection and sill give each bay physical depth.
    block(g,g,at+Vector3(0,size.y*.29,-.17),Vector3(size.x,.025,.025),material("reflection",Color("9cb9c2"),.2,.3))
    block(g,g,at+Vector3(0,-size.y*.5-.15,-.08),Vector3(size.x+.28,.16,.4),material("limestone",Color("b9b9aa")))

func building(g: Node, title: String, at: Vector3, dims: Vector3) -> void:
    var brick := material("brick",Color("ac8c7b"))
    var concrete := material("concrete",Color("c4c5b9"))
    var charcoal := material("charcoal",Color("35434a"),.65)
    var is_agora := title.begins_with("AGORA")
    var library := title.begins_with("PATERSON")
    var atac := title == "ATAC"
    var wall := concrete if library or atac else brick
    # Keep original collision footprint; articulate the visible envelope.
    block(g,g,at+Vector3(0,dims.y*.5,0),dims,wall,true)
    block(g,g,at+Vector3(0,.2,0),Vector3(dims.x+.3,.4,dims.z+.3),concrete)
    block(g,g,at+Vector3(0,dims.y+.12,0),Vector3(dims.x+.45,.24,dims.z+.45),charcoal)
    var front := at.z-dims.z*.5-.19
    var floors := 2 if is_agora else (4 if library else 5)
    var floor_height := (dims.y-.55)/floors
    var cols := 8 if is_agora else (7 if library else 12)
    if atac:
        # Faceted, gently bowed curtain wall, with projecting inclined fins.
        for col in range(cols):
            var x := at.x-dims.x*.5+(col+.5)*dims.x/cols
            var z := front-.9+.012*pow(x-at.x,2)
            for floor_id in range(floors):
                window(g,Vector3(x,1.55+floor_id*2.9,z),Vector2(1.24,2.65),col+floor_id)
            block(g,g,Vector3(x,7.9,z-.24),Vector3(.075,15.8,.3),concrete)
        for col in range(5):
            var fin := block(g,g,Vector3(at.x-7+col*3.5,7.7,front-1.1),Vector3(.32,15.4,1.15),concrete)
            fin.rotation_degrees.z = -7
        g._cylinder(g,at+Vector3(8.1,8.2,2.5),2.1,16.4,Color("748691"))
    else:
        for f in range(floors):
            var y := .8+floor_height*(f+.5)
            block(g,g,Vector3(at.x,y,front+.02),Vector3(dims.x-.5,2.1,.18),charcoal)
            for c in range(cols):
                var x := at.x-dims.x*.5+(c+.5)*dims.x/cols
                window(g,Vector3(x,y,front-.12),Vector2(dims.x/cols-.3,1.85 if library else 2.1),c+f)
            block(g,g,Vector3(at.x,y-1.25,front-.08),Vector3(dims.x+.3,.24,.55),concrete)
        # Side windows stop the building reading as a flat front pasted onto a box.
        for side in [-1,1]:
            for f in range(floors):
                for c in range(4):
                    var side_glass := material("sideglass",Color("486574"),.26,.5)
                    block(g,g,at+Vector3(side*(dims.x*.5+.07),1.9+f*floor_height,-dims.z*.5+1.6+c*2.7),Vector3(.16,1.65,1.9),side_glass)
    if atac:
        for side in [-1,1]:
            for f in range(5):
                for c in range(6):
                    var at_side := at+Vector3(side*(dims.x*.5+.1),1.7+f*2.9,-dims.z*.5+1.1+c*2.15)
                    block(g,g,at_side,Vector3(.19,2.45,1.94),material("atac_side",Color("456c80"),.2,.55))
                    block(g,g,at_side+Vector3(side*.05,-1.35,0),Vector3(.28,.17,2.15),concrete)
    # Ground-level glazed vestibule with recessed doors and real mullions.
    var entry_z := front-1.25
    block(g,g,Vector3(at.x,1.6,entry_z),Vector3(7.6,3.2,1.9),material("entryglass",Color("537f8c"),.16,.6))
    for i in range(7):
        var x := at.x-3.6+i*1.2
        block(g,g,Vector3(x,1.6,entry_z-1),Vector3(.075,3.2,.12),material("entryframe",Color("9daaa7"),.28,.65))
        if i in [2,3,4]:
            block(g,g,Vector3(x+.35,1.25,entry_z-1.09),Vector3(.035,.55,.06),concrete)
    block(g,g,Vector3(at.x,3.22,entry_z-.1),Vector3(8.4,.22,2.7),charcoal)
    block(g,g,Vector3(at.x,.1,entry_z-1.8),Vector3(10,.2,3.8),concrete)
    if is_agora:
        # Wide, low University Centre wings and red masonry piers.
        for side in [-1,1]:
            block(g,g,at+Vector3(side*11.2,2.5,1.4),Vector3(4.4,5,8.8),brick)
            for j in range(3):
                window(g,at+Vector3(side*11.2+(j-1)*1.25,2.7,-3.2),Vector2(1.02,2.7),j)
        for i in range(5):
            block(g,g,Vector3(at.x-8.6+i*4.3,3.7,front-.35),Vector3(.38,7.4,.65),brick)
        block(g,g,Vector3(at.x,4,entry_z-.98),Vector3(9.1,.9,.23),charcoal)
        facade_text(g,"AGORA  /  UNIVERSITY CENTRE",Vector3(at.x,4,entry_z-1.12),23)
    elif library:
        # Paterson: strong horizontal floor bands and its curved jade entrance canopy.
        block(g,g,at+Vector3(9.6,7.05,0),Vector3(2.5,14.1,12.9),brick)
        for i in range(23):
            var x := -4.7+i*.427
            var y := 3.45+1.35*(1-pow(x/4.8,2))
            var rib := block(g,g,Vector3(at.x+x,y,entry_z-1),Vector3(.43,.13,5.4),material("jade",Color("3c7778"),.3,.45))
            rib.rotation_degrees.z = -x*5
        for z in range(6):
            block(g,g,Vector3(at.x,3.52,entry_z-3.5+z),Vector3(9.5,.09,.06),charcoal)
        for x in [-4.6,4.6]:
            g._cylinder(g,Vector3(at.x+x,1.7,entry_z-3.1),.1,3.4,Color("a8babc"))
        facade_text(g,"CHANCELLOR PATERSON LIBRARY",Vector3(at.x,5.4,front-.48),24)
    elif atac:
        facade_text(g,"ATAC",Vector3(at.x,4.15,entry_z-1.15),36)
    # Roof parapets, ventilation banks and a perimeter reveal.
    for side in [-1,1]:
        block(g,g,at+Vector3(0,dims.y+.32,side*dims.z*.5),Vector3(dims.x,.4,.18),concrete)
    for i in range(3):
        block(g,g,at+Vector3(-3+i*3,dims.y+.55,1),Vector3(1.6,.8,2.3),charcoal)

func facade_text(g: Node, words: String, at: Vector3, size: int) -> void:
    var label: Label3D = g._sign(g,words,at,Color("e8e5d5"),size)
    label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
    label.pixel_size = .013
    label.outline_size = 2
    label.rotation.y = PI

func tree(g: Node, p: Node3D, at: Vector3, size: float) -> void:
    var n := Node3D.new()
    p.add_child(n)
    n.position = at
    n.scale = Vector3.ONE*size
    g._cylinder(n,Vector3(0,2.1,0),.19,4.2,Color("655c48"))
    var rng := RandomNumberGenerator.new()
    rng.seed = int(abs(at.x*139+at.z*713))
    for i in range(10):
        var a := i*2.4
        var h := 3.2+rng.randf()*2.5
        var branch: Node3D = g._cylinder(n,Vector3(cos(a)*.65,h-.8,sin(a)*.65),.075,1.8,Color("655c48"))
        branch.rotation = Vector3(sin(a)*.7,0,cos(a)*.7)
        var crown := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = 1.1+rng.randf()*.5
        mesh.height = mesh.radius*1.65
        mesh.radial_segments = 7
        mesh.rings = 4
        crown.mesh = mesh
        crown.position = Vector3(cos(a)*1.3,h,sin(a)*1.3)
        crown.material_override = material("leaf%d" % (i%4),[Color("335344"),Color("48664b"),Color("61784d"),Color("7a8452")][i%4])
        n.add_child(crown)

func royal(g: Node, p: Node3D, guardian: bool) -> void:
    var character = preload("res://guardian_art.gd").new()
    var pivots: Array[Node3D] = character.build(g,p,guardian)
    if guardian:
        limbs.append_array(pivots)


func animate(delta: float, speed: float) -> void:
    phase += delta * (9.0 if speed > .1 else 2.0)
    for i in range(limbs.size()):
        var amount := .48 if speed > .1 else .025
        limbs[i].rotation.x = sin(phase+(PI if i%2 else 0))*amount*(1 if i<2 else -1)

func courtyard(g: Node) -> void:
    var paving := material("paving",Color("c7c4b3"))
    var stone := material("concrete",Color("c4c5b9"))
    # Agora forecourt: a coherent paved gathering space with linear planting beds.
    block(g,g,Vector3(-8,.055,-25),Vector3(29,.08,10.8),paving)
    for z in [-29.5,-25,-21]:
        block(g,g,Vector3(-8,.104,z),Vector3(29,.012,.12),material("joint",Color("697570")))
    for x in range(-22,8,3):
        block(g,g,Vector3(x,.105,-25),Vector3(.08,.012,10.8),material("joint",Color("697570")))
    for x in [-22,5]:
        block(g,g,Vector3(x,.28,-25),Vector3(1.1,.5,7),stone)
        block(g,g,Vector3(x,.55,-25),Vector3(.88,.08,6.8),material("soil",Color("494c39")))
        for j in range(12):
            var at := Vector3(x,.72,-28+j*.53)
            g._sphere(g,at,.38,Color("5d704b"))
            for k in range(2):
                g._sphere(g,at+Vector3(.19*k,.29,.06),.08,Color("aa8e6b"))
    for x in [-18,-12,-6,0]:
        g._bench(Vector3(x,0,-29),0)
    for at in [Vector3(-24,0,-25),Vector3(8,0,-25),Vector3(-24,0,-8)]:
        tree(g,g,at,1.1)
    # Approach lights, slim bollards and bike hoops placed outside quest routes.
    for x in [-19,-16,-13]:
        var hoop: Node3D = g._ring(g,Vector3(x,.55,-31),.55,Color("53646a"))
        hoop.rotation_degrees.x = 90
    for x in [-21,4]:
        for z in [-30,-21]:
            g._cylinder(g,Vector3(x,.55,z),.09,1.1,Color("38484b"))
            g._cylinder(g,Vector3(x,.96,z),.105,.12,Color("e5d4aa"))
