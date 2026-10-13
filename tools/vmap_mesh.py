"""Meshe convexe pentru vmap (Hammer): element CMapMesh in format keyvalues2 dintr-o lista de puncte.

Folosit de tools/import_harta_688.py pentru trigger-ele hartii 6.88 (shop-uri, volumele camp-urilor, no-wards,
groapa lui Roshan): decompilarea hartii nu le recupereaza geometria, dar hull-urile de fizica ale modelelor
compilate exista, iar fiecare hull devine un mesh cu materialul toolstrigger, copil al entitatii (ca in Hammer).

Structura CDmePolygonMesh (half-edge) este cea scrisa de Hammer (verificata pe
content/dota/maps/prefabs/dota_pvp_prefab.vmap din Workshop Tools):
  * fiecare muchie are doua half-edge-uri 2k / 2k+1 (edgeOppositeIndices); edgeVertexIndices = varful DESTINATIE,
    vertexEdgeIndices[v] = un half-edge care pleaca din v, edgeNextIndices = urmatorul half-edge pe aceeasi fata;
  * fetele sunt in sens trigonometric privite din exterior (normala Newell = normala exterioara);
  * faceVertexData are cate o intrare pe half-edge (texcoord / normal / tangent ale varfului destinatie);
  * "origin" al CMapMesh este in coordonatele lumii, varfurile sunt relative la el.
"""
import math
import uuid


def _sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def _dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def _cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def _norm(a):
    n = math.sqrt(_dot(a, a))
    return (a[0] / n, a[1] / n, a[2] / n)


def angle_matrix(angles):
    """Coloanele (forward, left, up) ale rotatiei unui QAngle "pitch yaw roll" (conventia Source)."""
    p, y, r = (math.radians(a) for a in angles)
    sp, cp, sy, cy, sr, cr = math.sin(p), math.cos(p), math.sin(y), math.cos(y), math.sin(r), math.cos(r)
    forward = (cp * cy, cp * sy, -sp)
    left = (sr * sp * cy - cr * sy, sr * sp * sy + cr * cy, sr * cp)
    up = (cr * sp * cy + sr * sy, cr * sp * sy - sr * cy, cr * cp)
    return forward, left, up


def rotate(point, angles):
    f, l, u = angle_matrix(angles)
    x, y, z = point
    return tuple(x * f[i] + y * l[i] + z * u[i] for i in range(3))


def convex_faces(points, eps=0.05):
    """Varfurile si fetele (bucle de indici, trigonometric din exterior) ale infasuratoarei convexe a punctelor."""
    pts = []
    for p in points:
        if all(max(abs(p[i] - q[i]) for i in range(3)) > eps for q in pts):
            pts.append(tuple(p))
    planes = []
    n = len(pts)
    size = max(max(abs(c) for c in _sub(p, pts[0])) for p in pts) or 1.0
    for i in range(n):
        for j in range(i + 1, n):
            for k in range(j + 1, n):
                c = _cross(_sub(pts[j], pts[i]), _sub(pts[k], pts[i]))
                if math.sqrt(_dot(c, c)) < 1e-4 * size * size:
                    continue  # puncte (aproape) coliniare
                nrm = _norm(c)
                d = _dot(nrm, pts[i])
                side = [_dot(nrm, p) - d for p in pts]
                if max(side) > eps:
                    if min(side) < -eps:
                        continue  # planul taie corpul: nu e fata
                    nrm, d = (-nrm[0], -nrm[1], -nrm[2]), -d
                if any(_dot(nrm, q[0]) > 1 - 1e-6 and abs(d - q[1]) < eps for q in planes):
                    continue
                planes.append((nrm, d))
    faces = []
    for nrm, d in planes:
        on = [i for i, p in enumerate(pts) if abs(_dot(nrm, p) - d) <= eps]
        c = tuple(sum(pts[i][a] for i in on) / len(on) for a in range(3))
        u = _norm(_sub(pts[on[0]], c))
        w = _cross(nrm, u)
        on.sort(key=lambda i: math.atan2(_dot(_sub(pts[i], c), w), _dot(_sub(pts[i], c), u)))
        faces.append(on)
    return pts, faces


def half_edges(nverts, faces):
    """Tabelele half-edge (ca in CDmePolygonMesh) pentru un poliedru inchis."""
    edge_of, he_of = {}, {}
    for f, loop in enumerate(faces):
        for i, a in enumerate(loop):
            b = loop[(i + 1) % len(loop)]
            key = (min(a, b), max(a, b))
            if key not in edge_of:
                edge_of[key] = len(edge_of)
            h = 2 * edge_of[key] + (0 if a == key[0] else 1)
            if h in he_of:
                raise ValueError("mesh ne-manifold: muchia %s apare de doua ori in acelasi sens" % (key,))
            he_of[h] = (a, b, f)
    nh = 2 * len(edge_of)
    if len(he_of) != nh:
        raise ValueError("mesh deschis: %d half-edge-uri fara pereche" % (nh - len(he_of)))
    ev, ef, en = [0] * nh, [0] * nh, [0] * nh
    for h, (a, b, f) in he_of.items():
        ev[h], ef[h] = b, f
    fe = []
    for f, loop in enumerate(faces):
        hs = []
        for i, a in enumerate(loop):
            b = loop[(i + 1) % len(loop)]
            key = (min(a, b), max(a, b))
            hs.append(2 * edge_of[key] + (0 if a == key[0] else 1))
        for i, h in enumerate(hs):
            en[h] = hs[(i + 1) % len(hs)]
        fe.append(hs[0])
    ve = [None] * nverts
    for h in range(nh):
        origin = ev[h ^ 1]
        if ve[origin] is None:
            ve[origin] = h
    if nverts - len(edge_of) + len(faces) != 2:
        raise ValueError("caracteristica Euler gresita (V - E + F != 2)")
    return {"ve": ve, "ev": ev, "eo": [h ^ 1 for h in range(nh)], "en": en, "ef": ef, "fe": fe}


def _f(x):
    s = ("%.4f" % x).rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def _vec(v):
    return " ".join(_f(c) for c in v)


def _id():
    return str(uuid.uuid4())


def _array(kind, values, ind):
    if not values:
        return f'"{kind}" \n{ind}[\n{ind}]'
    body = ",\n".join(f'{ind}\t"{v}"' for v in values)
    return f'"{kind}" \n{ind}[\n{body}\n{ind}]'


def _stream(name, attr, kind, values, flags, ind):
    sem, idx = name.split(":")
    return (f'{ind}"CDmePolygonMeshDataStream"\n{ind}{{\n'
            f'{ind}\t"id" "elementid" "{_id()}"\n'
            f'{ind}\t"name" "string" "{name}"\n'
            f'{ind}\t"standardAttributeName" "string" "{attr}"\n'
            f'{ind}\t"semanticName" "string" "{sem}"\n'
            f'{ind}\t"semanticIndex" "int" "{idx}"\n'
            f'{ind}\t"vertexBufferLocation" "int" "0"\n'
            f'{ind}\t"dataStateFlags" "int" "{flags}"\n'
            f'{ind}\t"subdivisionBinding" "element" ""\n'
            f'{ind}\t"data" {_array(kind, values, ind + chr(9))}\n'
            f'{ind}}}')


def _data_array(name, size, streams, ind):
    body = ",\n".join(streams)
    return (f'{ind}"{name}" "CDmePolygonMeshDataArray"\n{ind}{{\n'
            f'{ind}\t"id" "elementid" "{_id()}"\n'
            f'{ind}\t"size" "int" "{size}"\n'
            f'{ind}\t"streams" "element_array" \n{ind}\t[\n{body}\n{ind}\t]\n'
            f'{ind}}}\n')


def _texture_axes(n):
    """Axele de textura aliniate la lume (ca "World align" din Hammer) pentru normala n."""
    ax, ay, az = abs(n[0]), abs(n[1]), abs(n[2])
    if az >= ax and az >= ay:
        return (1, 0, 0), (0, -1, 0)
    if ax >= ay:
        return (0, 1 if n[0] > 0 else -1, 0), (0, 0, -1)
    return (-1 if n[1] > 0 else 1, 0, 0), (0, 0, -1)


def cmapmesh(points, origin, material="materials/tools/toolstrigger.vmat", ind="\t\t\t\t\t", scale=0.25, texsize=64):
    """Elementul CMapMesh (text keyvalues2, cu indentarea ind) pentru infasuratoarea convexa a punctelor.

    points: varfurile relative la origin (deja rotite in coordonatele lumii); origin: pozitia mesh-ului in lume."""
    verts, faces = convex_faces(points)
    he = half_edges(len(verts), faces)
    nh, nf = len(he["ev"]), len(faces)
    normals = []
    for loop in faces:
        s = (0.0, 0.0, 0.0)
        for i, a in enumerate(loop):
            s = tuple(s[k] + v for k, v in enumerate(_cross(verts[a], verts[loop[(i + 1) % len(loop)]])))
        normals.append(_norm(s))
    axes = [_texture_axes(n) for n in normals]
    tc, nr, tg = [], [], []
    for h in range(nh):
        f, p = he["ef"][h], verts[he["ev"][h]]
        world = tuple(p[k] + origin[k] for k in range(3))
        u, v = axes[f]
        tc.append(f"{_f(_dot(world, u) / scale / texsize)} {_f(_dot(world, v) / scale / texsize)}")
        nr.append(_vec(normals[f]))
        t = _sub(u, tuple(_dot(u, normals[f]) * c for c in normals[f]))
        tg.append(_vec(_norm(t)) + " -1")
    i2, i3 = ind + "\t", ind + "\t\t"
    mesh = (f'{ind}"CMapMesh"\n{ind}{{\n'
            f'{i2}"id" "elementid" "{_id()}"\n'
            f'{i2}"children" "element_array" \n{i2}[\n{i2}]\n'
            f'{i2}"variableTargetKeys" "string_array" \n{i2}[\n{i2}]\n'
            f'{i2}"variableNames" "string_array" \n{i2}[\n{i2}]\n'
            f'{i2}"meshData" "CDmePolygonMesh"\n{i2}{{\n'
            f'{i3}"id" "elementid" "{_id()}"\n'
            f'{i3}"name" "string" "meshData"\n')
    for key, vals in (("vertexEdgeIndices", he["ve"]), ("vertexDataIndices", range(len(verts))),
                      ("edgeVertexIndices", he["ev"]), ("edgeOppositeIndices", he["eo"]),
                      ("edgeNextIndices", he["en"]), ("edgeFaceIndices", he["ef"]),
                      ("edgeDataIndices", [h // 2 for h in range(nh)]), ("edgeVertexDataIndices", range(nh)),
                      ("faceEdgeIndices", he["fe"]), ("faceDataIndices", range(nf))):
        mesh += f'{i3}"{key}" {_array("int_array", [str(x) for x in vals], i3)}\n'
    i4 = i3 + "\t\t"
    mesh += f'{i3}"materials" {_array("string_array", [material], i3)}\n'
    mesh += _data_array("vertexData", len(verts), [
        _stream("position:0", "position", "vector3_array", [_vec(p) for p in verts], 3, i4)], i3)
    mesh += "\n" + _data_array("faceVertexData", nh, [
        _stream("texcoord:0", "texcoord", "vector2_array", tc, 1, i4),
        _stream("normal:0", "normal", "vector3_array", nr, 1, i4),
        _stream("tangent:0", "tangent", "vector4_array", tg, 1, i4)], i3)
    mesh += "\n" + _data_array("edgeData", nh // 2, [
        _stream("flags:0", "flags", "int_array", ["0"] * (nh // 2), 3, i4)], i3)
    mesh += "\n" + _data_array("faceData", nf, [
        _stream("textureScale:0", "textureScale", "vector2_array", [f"{_f(scale)} {_f(scale)}"] * nf, 0, i4),
        _stream("textureAxisU:0", "textureAxisU", "vector4_array", [_vec(a[0]) + " 0" for a in axes], 0, i4),
        _stream("textureAxisV:0", "textureAxisV", "vector4_array", [_vec(a[1]) + " 0" for a in axes], 0, i4),
        _stream("materialindex:0", "materialindex", "int_array", ["0"] * nf, 8, i4),
        _stream("flags:0", "flags", "int_array", ["0"] * nf, 3, i4),
        _stream("lightmapScaleBias:0", "lightmapScaleBias", "int_array", ["0"] * nf, 1, i4)], i3)
    mesh += (f'\n{i3}"subdivisionData" "CDmePolygonMeshSubdivisionData"\n{i3}{{\n'
             f'{i3}\t"id" "elementid" "{_id()}"\n'
             f'{i3}\t"subdivisionLevels" {_array("int_array", ["0"] * nh, i3 + chr(9))}\n'
             f'{i3}\t"streams" "element_array" \n{i3}\t[\n{i3}\t]\n'
             f'{i3}}}\n\n'
             f'{i2}}}\n\n')
    for key, kind, val in (("physicsMissingDetailLayers", "element_array", None), ("physicsIncludedDetailLayers", "element_array", None),
                           ("lightGroup", "string", ""), ("precomputelightprobes", "bool", "1"), ("useAsOccluder", "bool", "0"),
                           ("bakelightoutput", "int", "-1"), ("excludefromimpostors", "bool", "0"),
                           ("origin", "vector3", _vec(origin)), ("angles", "qangle", "0 0 0"), ("scales", "vector3", "1 1 1"),
                           ("transformLocked", "bool", "0"), ("force_hidden", "bool", "0"), ("editorOnly", "bool", "0"),
                           ("customVisGroup", "string", ""), ("disableShadows", "int", "0"), ("bakelighting", "bool", "1"),
                           ("cubeMapName", "string", ""), ("visexclude", "bool", "0"), ("disablemerging", "bool", "0"),
                           ("renderwithdynamic", "bool", "0"), ("renderToCubemaps", "bool", "1"), ("keep_vertices", "bool", "0"),
                           ("fademindist", "float", "-1"), ("fademaxdist", "float", "0"), ("disableHeightDisplacement", "bool", "0"),
                           ("smoothingAngle", "float", "40"), ("tintColor", "color", "255 255 255 255"), ("renderAmt", "int", "255"),
                           ("physicsType", "string", "default"), ("physicsCollisionProperty", "string", ""), ("physicsGroup", "string", ""),
                           ("physicsInteractsAs", "string", ""), ("physicsInteractsWith", "string", ""),
                           ("physicsInteractsExclude", "string", ""), ("physicsSimplificationOverride", "bool", "0"),
                           ("physicsSimplificationError", "float", "0")):
        if val is None:
            mesh += f'{i2}"{key}" "{kind}" \n{i2}[\n{i2}]\n'
        else:
            mesh += f'{i2}"{key}" "{kind}" "{val}"\n'
    return mesh + f"{ind}}}"
