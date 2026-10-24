extends "res://guardian_art.gd"
# Original, locally authored quadruped. Articulated hips/knees/paws, not a static statue.
var legs: Array = []
var torso: Node3D
var head: Node3D
var tail: Node3D
var stride := 0.0
var rest := 0.0
var blend := 0.0

func build_sphinx(parent: Node3D) -> void:
    var stone := mat("sandstone", "bc925d", .08, .82)
    var gold := mat("gold", "e6bd62", .55, .33)
    var blue := mat("lapis", "164e80", .25, .42)
    var dark := mat("kohl", "202d36")
    torso = Node3D.new()
    parent.add_child(torso)
    # Anatomical, tapered lion barrel, shoulder mass and haunches.
    var body := loft(torso,[Vector3(.05,-1.22,.05),Vector3(.43,-1.03,.47),Vector3(.55,-.65,.54),Vector3(.48,.35,.44),Vector3(.60,.85,.61),Vector3(.43,1.17,.48),Vector3(.08,1.30,.1)],stone,16)
    body.rotation.x = PI/2
    body.position.y = 1.18
    orb(torso,Vector3(0,1.34,.90),Vector3(.64,.69,.58),stone)
    for side in [-1,1]:
        orb(torso,Vector3(side*.43,1.17,-.83),Vector3(.35,.48,.47),stone)
        orb(torso,Vector3(side*.48,1.22,.82),Vector3(.25,.5,.36),stone)
        for front in [true,false]:
            var origin := Vector3(side*.46,1.12,.83 if front else -.88)
            var pivot := Node3D.new()
            parent.add_child(pivot)
            pivot.position = origin
            var upper := tube(pivot,Vector3.ZERO,.19,.62,stone,.23)
            var lower := tube(pivot,Vector3.ZERO,.105,.64,stone,.17)
            var paw := orb(parent,Vector3(origin.x,.16,origin.z+.12),Vector3(.23,.16,.34),stone)
            for toe in [-1,0,1]:
                orb(paw,Vector3(toe*.30,-.06,.64),Vector3(.21,.34,.24),gold)
            legs.append({"origin":origin,"upper":upper,"lower":lower,"pivot":pivot,"paw":paw,"phase":0.0 if (front == (side == 1)) else PI,"front":front})
    # Raised human head with full striped nemes, ears, carved face and cobra.
    head = Node3D.new()
    torso.add_child(head)
    head.position = Vector3(0,1.45,1.03)
    tube(head,Vector3(0,.18,0),.33,.48,stone)
    loft(head,[Vector3(.22,.30,.23),Vector3(.31,.46,.29),Vector3(.36,.74,.29),Vector3(.32,1.02,.26)],stone,16)
    orb(head,Vector3(0,1.02,-.08),Vector3(.54,.29,.42),blue)
    for side in [-1,1]:
        panel(head,[Vector3(side*.34,1.10,.23),Vector3(side*.61,1.02,.14),Vector3(side*.72,.07,.13),Vector3(side*.43,.03,.30)],blue)
        panel(head,[Vector3(side*.61,1.02,.14),Vector3(side*.49,.98,-.34),Vector3(side*.58,.06,-.21),Vector3(side*.72,.07,.13)],blue)
        for i in range(10):
            var stripe := bar(head,Vector3(side*(.57-i*.007),.10+i*.09,.275),Vector3(.30,.026,.035),gold)
            stripe.rotation.z = side*.12
        orb(head,Vector3(side*.16,.78,.282),Vector3(.11,.035,.024),dark)
        orb(head,Vector3(side*.16,.78,.303),Vector3(.027,.019,.012),gold)
        var brow := bar(head,Vector3(side*.16,.86,.27),Vector3(.24,.042,.05),dark)
        brow.rotation.z = -side*.12
        orb(head,Vector3(side*.34,.6,.03),Vector3(.07,.12,.07),stone)
    panel(head,[Vector3(-.065,.81,.28),Vector3(.065,.81,.28),Vector3(.075,.59,.42),Vector3(-.075,.59,.42)],stone)
    bar(head,Vector3(0,.49,.28),Vector3(.19,.026,.04),mat("lip","6b4c37"))
    loft(head,[Vector3(.055,.10,.06),Vector3(.09,.38,.08)],gold,8).position.z=.29
    bar(head,Vector3(0,1.08,.31),Vector3(.76,.055,.055),gold)
    tube(head,Vector3(0,1.20,.29),.04,.23,gold)
    orb(head,Vector3(0,1.34,.30),Vector3(.075,.09,.045),gold)
    # Broad layered lapis-and-gold pectoral, extending around the lion chest.
    for i in range(13):
        var a: float = (i-6)*.21
        var plate := bar(torso,Vector3(sin(a)*.54,1.68-absf(sin(a))*.15,1.23+cos(a)*.32),Vector3(.11,.27,.06),gold)
        plate.rotation.z = -a*.35
        bar(torso,plate.position+Vector3(0,0,.037),Vector3(.065,.16,.02),blue)
    # Tail curls back from the haunches; animated at the root.
    tail=Node3D.new()
    torso.add_child(tail)
    tail.position=Vector3(0,1.35,-1.12)
    var previous:=Vector3.ZERO
    for i in range(1,9):
        var next:=Vector3(.30*sin(i*.32),-.04*i,-.13*i)
        var piece:=tube(tail,Vector3.ZERO,.065,.18,stone)
        segment(piece,previous,next,.18)
        previous=next
    orb(tail,previous,Vector3(.12,.13,.18),mat("tuft","715638"))
    animate_sphinx(0.0,0.0,0.0)

func segment(node: Node3D, a: Vector3, b: Vector3, length: float) -> void:
    node.position=(a+b)*.5
    var direction:=(b-a).normalized()
    var x:=Vector3.RIGHT
    if absf(direction.dot(x))>.95: x=Vector3.FORWARD
    var z:=x.cross(direction).normalized()
    node.basis=Basis(direction.cross(z).normalized(),direction,z)
    node.scale.y=a.distance_to(b)/length

func animate_sphinx(delta: float, speed: float, turn: float) -> void:
    rest+=delta
    blend=move_toward(blend,clampf(speed/3.0,0,1),delta*5)
    stride+=delta*speed*2.7
    for leg in legs:
        var phase: float = stride+leg.phase
        var cycle: float = fposmod(phase,TAU)/TAU
        # Constant backward stance speed matches world travel. Swing follows a raised arc.
        var travel: float = (lerpf(-.582,.582,smoothstep(0,1,cycle*2)) if cycle<.5 else lerpf(.582,-.582,(cycle-.5)*2))*blend
        var lift: float = sin(cycle*TAU)*.23*blend if cycle<.5 else 0.0
        var origin: Vector3 = leg.origin
        var target:=Vector3(0,-.96+lift,travel+.08)
        var hip:=Vector3.ZERO
        # Analytic two-bone IK with stable forward knees; paws stay parallel to ground.
        var distance:=clampf(target.length(),.35,1.18)
        var mid:=target*.5
        var bend:=sqrt(maxf(0,.62*.62-distance*distance*.25))
        var knee:=mid+Vector3(0,0,1 if leg.front else -1)*bend
        segment(leg.upper,hip,knee,.62)
        segment(leg.lower,knee,target,.64)
        leg.paw.position=origin+target
        leg.paw.rotation.x=0
    torso.position.y=sin(stride*2)*.025*blend+sin(rest*1.6)*.009
    torso.rotation.z=clampf(turn,-1,1)*.055*blend
    head.rotation.y=sin(rest*.6)*.025*(1-blend)
    tail.rotation.y=sin(rest*2+stride*.2)*.16
