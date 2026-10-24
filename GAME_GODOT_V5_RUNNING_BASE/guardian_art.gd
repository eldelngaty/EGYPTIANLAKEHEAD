extends RefCounted
# Authored low-poly royal characters. Meshes, materials and animation pivots are local.
var mats: Dictionary = {}
func mat(key: String, color: String, metal := 0.0, roughness := .55) -> StandardMaterial3D:
    if mats.has(key): return mats[key]
    var m:=StandardMaterial3D.new()
    m.albedo_color=Color(color)
    m.metallic=metal
    m.roughness=roughness
    mats[key]=m
    return m
func mesh_node(parent: Node3D, mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
    var node:=MeshInstance3D.new()
    parent.add_child(node)
    node.mesh=mesh
    node.position=at
    node.material_override=material
    return node
func orb(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
    var mesh:=SphereMesh.new()
    mesh.radius=1
    mesh.height=2
    mesh.radial_segments=12
    mesh.rings=6
    var node:=mesh_node(parent,mesh,at,material)
    node.scale=size
    return node
func bar(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
    var mesh:=BoxMesh.new()
    mesh.size=size
    return mesh_node(parent,mesh,at,material)
func tube(parent: Node3D, at: Vector3, radius: float, height: float, material: Material, top := -1.0) -> MeshInstance3D:
    var mesh:=CylinderMesh.new()
    mesh.bottom_radius=radius
    mesh.top_radius=radius if top<0 else top
    mesh.height=height
    mesh.radial_segments=12
    return mesh_node(parent,mesh,at,material)
func panel(parent: Node3D, points: Array, material: Material) -> MeshInstance3D:
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(1,points.size()-1):
        for index in [0,i,i+1]: st.add_vertex(points[index])
    st.generate_normals()
    var m:=material.duplicate() as StandardMaterial3D
    m.cull_mode=BaseMaterial3D.CULL_DISABLED
    return mesh_node(parent,st.commit(),Vector3.ZERO,m)
func loft(parent: Node3D, rings: Array, material: Material, segments := 12) -> MeshInstance3D:
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for j in range(rings.size()-1):
        for i in range(segments):
            var a:=TAU*i/segments
            var b:=TAU*(i+1)/segments
            var r0: Vector3=rings[j]
            var r1: Vector3=rings[j+1]
            var points: Array[Vector3]=[Vector3(sin(a)*r0.x,r0.y,cos(a)*r0.z),Vector3(sin(b)*r0.x,r0.y,cos(b)*r0.z),Vector3(sin(b)*r1.x,r1.y,cos(b)*r1.z),Vector3(sin(a)*r1.x,r1.y,cos(a)*r1.z)]
            for k in [0,2,1,0,3,2]: st.add_vertex(points[k])
    st.generate_normals()
    return mesh_node(parent,st.commit(),Vector3.ZERO,material)
func build(_g: Node, parent: Node3D, guardian: bool) -> Array[Node3D]:
    var skin:=mat("skin","ad7851",0,.82)
    var gold:=mat("gold","d5ab4c",.65,.3)
    var lapis:=mat("lapis","124d90",.28,.3)
    var bright_blue:=mat("blue","2779a9",.22,.42)
    var linen:=mat("linen","e3dec4",0,.9)
    var dark:=mat("kohl","14242d",0,.9)
    var leather:=mat("leather","473c32",0,.95)
    var limbs: Array[Node3D]=[]
    for side in [-1,1]:
        var leg:=Node3D.new()
        parent.add_child(leg)
        leg.position=Vector3(side*.24,1.65,0)
        loft(leg,[Vector3(.18,-1.39,.16),Vector3(.16,-.9,.16),Vector3(.19,-.5,.18),Vector3(.2,0,.2)],skin,10)
        bar(leg,Vector3(0,-1.52,.12),Vector3(.36,.16,.62),leather)
        bar(leg,Vector3(0,-1.42,.19),Vector3(.36,.045,.16),gold)
        tube(leg,Vector3(0,-1.25,0),.18,.13,gold)
        if guardian: limbs.append(leg)
    var torso:=loft(parent,[Vector3(.34,1.7,.22),Vector3(.42,2.03,.25),Vector3(.59,2.46,.28),Vector3(.5,2.62,.22)],skin)
    parent.set_meta("royal_chest",torso)
    if guardian:
        loft(parent,[Vector3(.65,1.05,.43),Vector3(.48,1.75,.3)],linen,16)
        for i in range(12):
            var angle: float=(i-5.5)*.135
            var x: float=sin(angle)*.57
            bar(parent,Vector3(x,1.35,.39*cos(angle)),Vector3(.014,.57,.018),mat("linen_shadow","b9b499"))
    else:
        loft(parent,[Vector3(.62,.16,.42),Vector3(.47,1.5,.31),Vector3(.35,1.83,.25),Vector3(.48,2.35,.28)],linen,16)
    tube(parent,Vector3(0,1.76,0),.49,.13,gold)
    panel(parent,[Vector3(-.22,1.73,.34),Vector3(.22,1.73,.34),Vector3(.27,.98,.46),Vector3(-.27,.98,.46)],gold)
    panel(parent,[Vector3(-.17,1.7,.35),Vector3(.17,1.7,.35),Vector3(.19,1.05,.47),Vector3(-.19,1.05,.47)],lapis)
    # Broad segmented Egyptian collar; strong blue, turquoise and gold separation.
    for i in range(13):
        var angle: float=(i-6)*.23
        var x: float=sin(angle)*.59
        var z: float=cos(angle)*.32
        var plate:=bar(parent,Vector3(x,2.43-absf(sin(angle))*.04,z),Vector3(.11,.23,.075),gold)
        plate.rotation.z=-angle*.4
        bar(parent,Vector3(x,2.44,z+.045),Vector3(.063,.13,.025),bright_blue)
    orb(parent,Vector3(0,2.22,.3),Vector3(.15,.11,.035),gold)
    orb(parent,Vector3(0,2.23,.34),Vector3(.075,.10,.035),lapis)
    tube(parent,Vector3(0,2.67,0),.17,.28,skin)
    # Carved Sphinx-like head: planar jaw, full cheekbones and a visible nose.
    loft(parent,[Vector3(.20,2.78,.21),Vector3(.29,2.91,.26),Vector3(.34,3.19,.28),Vector3(.30,3.48,.25)],skin,12)
    for side in [-1,1]:
        orb(parent,Vector3(side*.15,3.23,.258),Vector3(.105,.041,.024),dark)
        orb(parent,Vector3(side*.15,3.235,.28),Vector3(.037,.022,.012),mat("iris","c8a161"))
        var brow:=bar(parent,Vector3(side*.15,3.32,.26),Vector3(.23,.043,.05),dark)
        brow.rotation.z=-side*.13
        orb(parent,Vector3(side*.3,3.07,.02),Vector3(.07,.13,.055),skin)
    panel(parent,[Vector3(-.07,3.25,.27),Vector3(.07,3.25,.27),Vector3(.065,3.06,.39),Vector3(-.065,3.06,.39)],skin)
    bar(parent,Vector3(0,2.96,.253),Vector3(.17,.025,.035),mat("mouth","57382d"))
    if guardian:
        # Nemes headdress: flared lappets and a cobra, rather than a featureless cap.
        orb(parent,Vector3(0,3.48,-.055),Vector3(.57,.29,.42),lapis)
        tube(parent,Vector3(0,3.52,0),.46,.07,gold)
        for side in [-1,1]:
            panel(parent,[Vector3(side*.40,3.52,.24),Vector3(side*.66,3.47,.16),Vector3(side*.78,2.68,.19),Vector3(side*.47,2.64,.31)],lapis)
            panel(parent,[Vector3(side*.66,3.47,.16),Vector3(side*.52,3.42,-.30),Vector3(side*.62,2.65,-.13),Vector3(side*.78,2.68,.19)],bright_blue)
            for stripe in range(8):
                var y:=2.7+stripe*.097
                var x: float=side*(.615-(stripe*.009))
                var band:=bar(parent,Vector3(x,y,.282),Vector3(.31,.029,.035),gold)
                band.rotation.z=side*.09
        tube(parent,Vector3(0,3.64,.37),.044,.28,gold)
        orb(parent,Vector3(0,3.81,.38),Vector3(.09,.105,.055),gold)
        bar(parent,Vector3(0,2.77,.26),Vector3(.115,.20,.105),lapis)
    else:
        # Nefertiti's unmistakable tall, flat-topped blue crown.
        tube(parent,Vector3(0,3.76,-.025),.36,.88,lapis,.61)
        tube(parent,Vector3(0,3.34,-.025),.37,.09,gold)
        tube(parent,Vector3(0,4.19,-.025),.61,.05,gold)
        bar(parent,Vector3(0,3.78,.46),Vector3(.045,.74,.025),gold)
        for side in [-1,1]:
            orb(parent,Vector3(side*.34,2.96,.07),Vector3(.065,.13,.025),gold)
    for side in [-1,1]:
        var arm:=Node3D.new()
        parent.add_child(arm)
        arm.position=Vector3(side*.65,2.4,0)
        orb(arm,Vector3(0,-.03,0),Vector3(.23,.23,.22),skin)
        loft(arm,[Vector3(.11,-1.03,.11),Vector3(.14,-.66,.13),Vector3(.17,-.5,.16),Vector3(.19,-.12,.18)],skin,10)
        tube(arm,Vector3(0,-.19,0),.20,.14,gold)
        tube(arm,Vector3(0,-.91,0),.14,.15,gold)
        orb(arm,Vector3(0,-1.09,.05),Vector3(.12,.15,.085),skin)
        for i in range(3): bar(arm,Vector3((i-1)*.05,-1.15,.12),Vector3(.036,.15,.045),skin)
        if guardian:
            limbs.append(arm)
            if side==1:
                tube(arm,Vector3(.10,-.51,.14),.035,3.03,gold)
                var ring:=TorusMesh.new()
                ring.inner_radius=.145
                ring.outer_radius=.20
                ring.rings=16
                ring.ring_segments=12
                var top:=mesh_node(arm,ring,Vector3(.10,1.15,.14),gold)
                top.rotation.x=PI/2
                bar(arm,Vector3(.10,.86,.14),Vector3(.53,.06,.06),gold)
                orb(arm,Vector3(.10,1.14,.14),Vector3(.09,.13,.025),bright_blue)
    return limbs
