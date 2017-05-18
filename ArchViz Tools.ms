/*  
[INFO] 

NAME = ArchViz Tools
VERSION = 1.1.3
AUTHOR = MastaMan
DEV = Visco CG
HELP = 

[INSTALL]

MACRO=ArchVizTools
CAT=ARCHVIZ
TEXT=ArchViz Tools
ICON=#("PhysX_Main",27)

[1.0.0]

* First release =

[1.0.1]

+ Added: Mask By ObjectID =
+ Added: Buttons for delete Render Elements=
+ Added: Mask By Color=
+ Added: Button Random Object Color=

[1.0.2]

+ Added: Light Select Element=
* Fixed Mask By ObjectID. Now works for instances=

[1.0.3]

+ Added: Ambient Occlusion Elements=

[1.0.4]

+ Added: Support blend materials for MatID=

[1.0.5]

+ Added: Change AO when set radius in spinners=

[1.1.0]

+ Added: Check dublicated LightSelect render elements=

[1.1.1]

- BugFix: Propogare to delete MatID Elements=
- BugFix: MatID id dublication=
- BugFix: Default numbers for Small and Large AO=
+ Added: Confirm message on delete elements=

[1.1.2]
- BugFix: Not clear all effect id in materials=

[1.1.3]

+ Added: Support - VRayBlendMtl, VRayMtlWrapper, VrayOverrideMtl, VRay2SidedMtl=
+ Added: Support for XRef Scene=

[ABOUT]

This script helps to quickly add Render Elements for masks=

[TEST]

[SCRIPT]
*/	


fn getScriptInfo s releaseInfo: "" =
(		
	if(releaseInfo != "") do
	(
		r = getINISetting s releaseInfo
		return r
	)
	
	v = getINISetting s "INFO" "VERSION"
	a = getINISetting s "INFO" "AUTHOR"
	n = getINISetting s "INFO" "NAME"
	o = getINISetting s "ABOUT"
	c = getINISetting s "INFO" "DEV"
	h = getINISetting s "INFO" "HELP"
	
	r = for i in (getINISetting s) where i != "ABOUT" and i != "SCRIPT" and i != "COPY" collect i
	
	return #(n, a, v, o, r, c, h)
)

fn parseToLine m = 
(
	if(m.count == 0) do return ""
	
	l = ""				
	for i in m do l += i + "\n"
	return l
)

rollout  _rRenderElement "Render Elements" 
(	
	local sMaterials = #()
	
	group "MultiMatteElements"
	(
		button btnCreateMtlIds "MatID" width: 120 across: 2 offset: [48, 0] align: #right		
		button btnDelMtlIds "X" width: 25  offset: [4, 0] align: #right tooltip: "Delete all MatID Render Elements" 
		button btnCreateObjIds "ObjectID" width: 120 across: 2 offset: [48, 0] align: #right	
		button btnDelObjIds "X" width: 25  offset: [4, 0] align: #right tooltip: "Delete all ObjectID Render Elements"
		checkbox cbxTreatXRef "Treat XRef Scene" checked: true
	)

	group "VrayWireColor"
	(
		button btnWireColor "Mask by Color" width: 117 across: 2 offset: [6, 0]		
		button btnDelWireColor "X" width: 25  offset: [4, 0] tooltip: "Delete VrayWireColor Render Element" align: #right
		radiobuttons rdoRandomWireColor "Random Object Color:" labels: #("Don't Change", "By Objects", "By Instances") align: #left				
	)
	
	group "VrayLightSelect"
	(		
		button btnLightselect "Light Select" width: 120 across: 2 offset: [-2, 0]
		button btnDelLightSelect "X" width: 25  offset: [27, 0] tooltip: "Delete all LightSelect Render Elements"
	)
	
	group "Ambient Occlusion"
	(
		button btnSmallAO "Small AO" width: 120 across: 2 offset: [48, 0] align: #right
		button btnDelSmallAO "X" width: 25  offset: [4, 0] tooltip: "Delete Small AO Render Element" align: #right
		spinner spnSmallAO "Small AO Radius: " range: [0, 99999, (units.decodeValue "15.0cm")]fieldWidth: 50 type: #worldunits align: #right
		
		button btnLargeAO "Large AO" width: 120 across: 2 offset: [48, 0] align: #right
		button btnDelLargeAO "X" width: 25  offset: [4, 0] tooltip: "Delete Large AO Render Element" align: #right
		spinner spnLargeAO "Large AO Radius: " range: [0, 99999, (units.decodeValue "40.0cm")] fieldWidth: 50 type: #worldunits align: #right
	)
	
	fn isVray =
	(
		_Vray = renderers.current
		if(matchPattern (_Vray as string) pattern:"V_Ray_Adv*") do return true
		return false
	)

	fn deleteMessage h:"" n: true =
	(
		s = if(n) then "s" else ""
		return not (queryBox ("Do you want to delete " + h + " element" + s + "?") title: "Confirm deletion!")
	)
	
	fn appendMaterial m = 
	(	
		for i in m where findItem sMaterials i == 0 do append sMaterials i		
	)
	
	fn getXRefMaterials =
	(
		mats = #()
		xr = for i in 1 to xrefs.getXRefFileCount() collect xrefs.getXRefFile i
		for i in xr do 
		(
			c = i.tree.children
			m = for i in c where i != undefined and i.material != undefined collect i.material
			m = makeUniqueArray m
					
			for i in m do for ii in getClassInstances VrayMtl target: i do append mats ii	
		)
		
		return mats
	)
	
	fn getXRefObjects =
	(
		obj = #()
		xr = for i in 1 to xrefs.getXRefFileCount() collect xrefs.getXRefFile i
		for i in xr do join obj i.tree.children
				
		return for i in obj where superClassOf i == GeometryClass collect i
	)
	
	fn existElement el =
	(
		re = maxOps.GetCurRenderElementMgr()
		n = re.NumRenderElements()
		
		for i in 0 to n where (re.GetRenderElement i) != undefined and (MatchPattern (re.GetRenderElement i).elementName pattern: el) do return true
		
		return false
	)
	
	fn removeElemet re n el = 
	(	
		for i in 0 to n - 1 where (re.GetRenderElement i) != undefined and (MatchPattern (re.GetRenderElement i).elementName pattern: el) do re.RemoveRenderElement (re.GetRenderElement i)	
	)
	
	fn deleteElements el =
	(			
		re = maxOps.GetCurRenderElementMgr()
		n = re.NumRenderElements()
		
		for i in 1 to n do removeElemet re n el				
			
		renderSceneDialog.open()
	)
	
	fn findElement n =
	(
		re = maxOps.GetCurRenderElementMgr()
		c = re.NumRenderElements()
		
		el = #()
		for i in 0 to c - 1 where (re.GetRenderElement i) != undefined and (MatchPattern (re.GetRenderElement i).elementName pattern: n) do append el (re.GetRenderElement i)
		
		return el
	)
	
	fn addElement el n =
	(		
		el.elementName = n
		re = maxOps.GetCurRenderElementMgr()				
		re.AddRenderElement el	
					
		renderSceneDialog.open()
	)
	
	fn existInLightElement ll =
	(
		el = findElement "LightSelect_*"
		
		findElements = #()
		
		for i in el do
		(
			l = i.lights
			
			c = makeUniqueArray (i.lights as array)
						
			if(c.count == 1 and c[1] == undefined) do
			(
				re = maxOps.GetCurRenderElementMgr()
				re.RemoveRenderElement i
				continue
			)
			
			for ii in l where findItem ll ii !=0 do appendIfUnique findElements i			
		)
		
		if(findElements.count > 0) do return findElements[1]
		return undefined
	)
	
	fn getUniqueName name =
	(
		el = findElement name
		n = filterString name "*"
		
		a = #(0)
		
		for i in el do
		(
			l = filterString i.ElementName "_"
			
			append a (l[l.count] as integer)
		)
		
		m = amax a
		
		return n[1] + ((m + 1) as string)
	)
	
	fn getInstances o =
	(	
		sceneInst = #()
				 
		for i in o do 
		(	
			InstanceMgr.GetInstances i &tmpInst
			
			doAppend = false
			for ii in sceneInst where findItem ii i != 0 do doAppend = true
			
			if(doAppend == false) do append sceneInst tmpInst
		)
		
		return sceneInst
	)
	
	fn resetMatId = 
	(
		for i in getClassInstances VrayMtl do
		(
			try(i.override_effect_id = off)catch()
			try(i.effect_id = 0)catch()
		)
	)
	
	fn resetObjectID = for i in geometry do i.gbufferchannel = 0
	
	fn randomWireColor =
	(
		case (rdoRandomWireColor.state) of
		(
			2: for i in geometry do i.wirecolor = random black white
			3:
			(
				g = getInstances geometry
				
				for i in g where i != undefined do
				(
					c = random black white
					for ii in i do ii.wirecolor = c
				)
			)
		)
	)
	
	fn createObjIds g =
	(
		objById = getInstances g
		
		for i in 1 to objById.count do for c in objById[i] do c.gbufferchannel = i
		
		for i in 1 to objById.count by 3 do
		(
			mme = MultiMatteElement()
			n =  "ObjectID_MultiMatteElement " + i as string + " - " + (i + 2) as string
			mme.MatID = false
			mme.R_gbufID = i
			mme.G_gbufID = i + 1
			mme.B_gbufID = i + 2
				
			addElement mme n
		)
	)
		
	on _rRenderElement open do
	(
		if(isVray() == false) do 
		(
			messageBox "Please assign Vray Render!" title: "Warning!"
			try(closeRolloutFloater  rArchVizTools) catch()
		)
		
		el = findElement "VRayExtraTex_Small AO"
		
		if(el.count > 0 and classOf el[1].texture == VRayDirt) do
		(
			spnSmallAO.value = el[1].texture.radius
		)
		
		el = findElement "VRayExtraTex_Large AO"
		
		if(el.count > 0 and classOf el[1].texture == VRayDirt) do
		(
			spnLargeAO.value = el[1].texture.radius
		)
		
	)
	
	on btnDelMtlIds pressed do 
	(	
		if(deleteMessage h:"MtlID") do return false
		
		deleteElements "MtlID_*"
		deleteElements "Sel_MtlID_*"
		resetMatId()
	)
	on btnDelObjIds pressed do
	(		
		if(deleteMessage h:"ObjectID") do return false
		
		deleteElements "ObjectID_*"
		deleteElements "Sel_ObjectID_*"
		resetObjectID()
	)
	
	on btnDelWireColor pressed do
	(
		if(deleteMessage h:"Object Color Mask" n: false) do return false
		
		deleteElements "Object Color Mask"
	)
	on btnDelLightSelect pressed do 
	(	
		if(deleteMessage h:"LightSelect") do return false
		
		deleteElements "LightSelect_*"
	)
	
	on btnLightselect pressed do
	(
		sceneLights = for i in lights where isKindOf i light collect i

		instanceLights = getInstances sceneLights

		for i in 1 to instanceLights.count do
		(
			ll = instanceLights[i]
						
			n = existInLightElement ll
					
			if(n == undefined) then
			(
				vls = VRayLightSelect()
				n = getUniqueName "LightSelect_*"
				vls.lights = ll
				
				addElement vls n
			)
			else
			(
				n.lights = ll
			)
		)
	)
	
	on btnWireColor pressed do
	(
		randomWireColor()
		
		n = "Object Color Mask"		
		if(existElement n == true) do return false
				
		vwc = VrayWireColor()
				
		addElement vwc n
	)
	

	on btnCreateObjIds pressed do
	(
		deleteElements "ObjectID_*"
		deleteElements "Sel_ObjectID_*"
		
		resetObjectID()
		
		o = geometry as array
		
		if(cbxTreatXRef.checked) do
		(
			t = getXRefObjects()
			join o t
		)
		
		createObjIds o	
	)
	
	on btnCreateMtlIds pressed do
	(	
		deleteElements "MtlID_*"
		deleteElements "Sel_MtlID_*"
		
		sMaterials = #()
		
		renderSceneDialog.open()
		
		-- Get Materials
		g = geometry
		for i in g where i.material != undefined do 
		(	
			m = i.material
			
			t = for ii in getClassInstances VRayMtl target: m collect ii
			
			appendMaterial t	
		)
		
		if(cbxTreatXRef.checked) do
		(
			xRefMats = getXRefMaterials()
			appendMaterial xRefMats
		)
	
		dubIds = #()
		dubMaterials = #()
		unusedMaterials = #()
				
		for i in sMaterials do
		(
			if(i.effect_id != 0 and (appendIfUnique dubIds i.effect_id) == false) do i.effect_id = 0
			
			if(i.effect_id == 0) do append unusedMaterials i
		)
				
		startFrom = amax (for i in sMaterials collect i.effect_id)
			
		for i in 1 to unusedMaterials.count do
		(
			unusedMaterials[i].override_effect_id = on
			unusedMaterials[i].effect_id = startFrom + i
		)
		
		for i in 1 to sMaterials.count by 3 do
		(
			id1 = sMaterials[i].effect_id
			id2 = if(sMaterials[i + 1] != undefined) then sMaterials[i + 1].effect_id else 0
			id3 = if(sMaterials[i + 2] != undefined) then sMaterials[i + 2].effect_id else 0
			
			mme = MultiMatteElement()
			n = "MtlID_MultiMatteElement " + id1 as string + ", " + id2 as string + ", " + id3 as string
			mme.MatID = true
			mme.R_gbufID = id1
			mme.G_gbufID = id2
			mme.B_gbufID = id3
				
			addElement mme n
		)
	)
	
	fn getAOname n =
	(
		z = filterString n "_"
		return z[2]
	)
	
	on btnSmallAO pressed do
	(
		n = "VRayExtraTex_Small AO"
		deleteElements n
		
		vet = VRayExtraTex()		
		vet.texture = VrayDirt()
		vet.texture.radius = spnSmallAO.value
		vet.texture.name = getAOname n
		vet.texture.subdivs = 32
			
		addElement vet n
	)
	
	on btnDelSmallAO pressed do 
	(	
		if(deleteMessage h:"VRayExtraTex_Small AO" n: false) do return false		
		
		deleteElements "VRayExtraTex_Small AO"
	)
		
	on btnLargeAO pressed do
	(
		n = "VRayExtraTex_Large AO"
		deleteElements n
				
		vet = VRayExtraTex()		
		vet.texture = VrayDirt()
		vet.texture.radius = spnLargeAO.value
		vet.texture.name = getAOname n
		vet.texture.subdivs = 32
			
		addElement vet n
	)
	
	on btnDelLargeAO pressed do 
	(	
		if(deleteMessage h:"VRayExtraTex_Large AO" n: false) do return false	
		
		deleteElements "VRayExtraTex_Large AO"
	)
		
	
	fn changeElementAO n x =
	(
		el = findElement n
		
		if(el.count > 0 and classOf el[1].texture == VRayDirt) then
		(
			el[1].texture.radius = x
			el[1].texture.subdivs = 32
			el[1].elementName = n
		)		
		else
		(					
			vet = VRayExtraTex()		
			vet.texture = VrayDirt()
			vet.texture.radius = x
			vet.texture.subdivs = 32
			vet.texture.name = getAOname n
				
			addElement vet n
		)
	)
	
	on spnSmallAO changed x do
	(
		n = "VRayExtraTex_Small AO"
		
		changeElementAO n x
	)
	
	on spnLargeAO changed x do
	(
		n = "VRayExtraTex_Large AO"
		
		changeElementAO n x				
	)
)


rollout _rAbout "About" 
(
	label lblName "" 
	label lblVer "" 
	
	label lblAuthor "" height: 30
	label lblCopy ""  height: 30
	
	on _rAbout open do
	(		
		i = getScriptInfo (getThisScriptFilename())
			
		lblName.caption = i[1]
		lblAuthor.caption = i[2]
		lblVer.caption = i[3]
		lblCopy.caption = i[6]
	)
)

try(closeRolloutFloater rArchVizTools) catch()
global rArchVizTools = newRolloutFloater "ArchViz" 180 450

addRollout _rRenderElement rArchVizTools rolledUp:false 
addRollout _rAbout rArchVizTools rolledUp:true 


