option explicit

!INC Local Scripts.EAConstants-VBScript

' Script Name: TNITS2OWL
' Author: Knut Jetlund
' Purpose: Export the INSPIRE TN UML Model to OWL
' Date: 20220704
'

'-----------------------------------------------------------------------------------------------------------------------------------
'Constants
'const owlURI = "http://spec.tn-its.eu/owl/tnits-owl"
const owlPath = "C:\Users\knjetl\Statens vegvesen\Videreutvikling dataplattform - 7.1 Leveranse Inspire TN ITS\Ontologier"
'const filename = "tnits-owl"
'const strPrefix = "tnits"

'-----------------------------------------------------------------------------------------------------------------------------------
'Global parameters
dim owlURI, strPrefix, filename, rootTitle, creator, fcd, clr, enr
dim objFSO, objOTLFile
dim thePackage as EA.Package
dim pck as EA.Package
dim el as EA.Element
dim relEl as EA.Element
dim eTag as EA.TaggedValue
dim con as EA.Connector
dim conEnd as EA.ConnectorEnd
dim conInverseEnd as EA.ConnectorEnd
dim rTag as EA.RoleTag
dim attr as EA.Attribute
dim aTag as EA.AttributeTag
dim lstOP, lstDP
dim definition, rangeName
dim strDjFeature, strDjCode, strDjEnum, strDjDT
dim coreClass
dim lstClasses, lstUniquePropertyNames, lstDuplicatePropertyNames, lstGlobalPropertyNames, lstCreatedProperties
dim propertyName, propertyDef, className
dim inverseProperty, inverseStatement
dim isGlobal, hasGlobalRange
dim i
dim dt, range, lower, upper
dim oneOfEnum
dim equivalentTo, subclassOf, hasURI

'-----------------------------------------------------------------------------------------------------------------------------------


sub heading
	'Heading for the ontology - content should be configurable
	'---------------------------------------------------------------------------------------------------------------------------
	'Namespaces for the ontology
	'objOTLFile.WriteText "" & vbCrLf
	objOTLFile.WriteText "@prefix : <" & owlURI & "#> ." & vbCrLf
	'ISO 19148 from the INTERLINK Ontologies
	objOTLFile.WriteText "@prefix lr: <http://www.roadotl.eu/iso19148/def/> ." & vbCrLf
	'OGC Simple feature
	objOTLFile.WriteText "@prefix sf: <http://www.opengis.net/ont/sf#> ." & vbCrLf
	'OGC GeoSPARQL
	objOTLFile.WriteText "@prefix gsp: <http://www.opengis.net/ont/geosparql#> ." & vbCrLf
	'W3C Core ontologies
	objOTLFile.WriteText "@prefix owl: <http://www.w3.org/2002/07/owl#> ." & vbCrLf
	objOTLFile.WriteText "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> ." & vbCrLf
	objOTLFile.WriteText "@prefix xml: <http://www.w3.org/XML/1998/namespace> ." & vbCrLf
	objOTLFile.WriteText "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> ." & vbCrLf
	objOTLFile.WriteText "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> ." & vbCrLf
	objOTLFile.WriteText "@prefix skos: <http://www.w3.org/2004/02/skos/core#> ." & vbCrLf
	objOTLFile.WriteText "@prefix dc: <http://purl.org/dc/terms/> ." & vbCrLf
	objOTLFile.WriteText "@base <http://inspire.ec.europa.eu/isotc211> ." & vbCrLf

	objOTLFile.WriteText vbCrLf
	objOTLFile.WriteText "<" & owlURI & "> a owl:Ontology ;" & vbCrLf
	
	' -------------------------------------------------------------------------
	'Imports
	'SKOS
	objOTLFile.WriteText "	owl:imports <http://www.w3.org/2004/02/skos/core> ;" & vbCrLf
	'OGC GeoSparql
	objOTLFile.WriteText "	owl:imports gsp: ;" & vbCrLf
	'ISO/TC 211 types
	objOTLFile.WriteText "	owl:imports <http://inspire.ec.europa.eu/isotc211> ;" & vbCrLf
	'ISO 19148 from the INTERLINK Ontologies
	'objOTLFile.WriteText "	owl:imports lr: ;" & vbCrLf
	'ISO 19115 Metadata
	'objOTLFile.WriteText "	owl:imports <http://def.isotc211.org/iso19115/-1/2014/MetadataInformation> ;" & vbCrLf
	'TN-ITS Codes
	'objOTLFile.WriteText "	owl:imports <http://spec.tn-its.eu/codelists/allcodes> ;" & vbCrLf
	
	
	'Notes on paths
	objOTLFile.WriteText vbCrLf
	objOTLFile.WriteText "	### GeoSPARQL rdf file: http://schemas.opengis.net/geosparql/1.0/geosparql_vocab_all.rdf" & vbCrLf
	objOTLFile.WriteText "	### ISO 19148 ttl file: https://ontologi.atlas.vegvesen.no/nvdb/core/iso-19148.ttl" & vbCrLf
	objOTLFile.WriteText "	### ISO 19115 rdf file: http://def.isotc211.org/iso19115/-1/2014/MetadataInformation.rdf" & vbCrLf
	objOTLFile.WriteText vbCrLf
	
	
	' --------------------------------------------------------------------
	
	'Ontology metadata 
	objOTLFile.WriteText "	dc:creator """ & creator & """ ;" & vbCrLf
	objOTLFile.WriteText "	dc:date """ & left(Now,10) & """ ;" & vbCrLf
	objOTLFile.WriteText "	dc:description ""Ontology for " & thePackage.Name & ", derived from the UML model""@en ;" & vbCrLf
	objOTLFile.WriteText "	dc:title """ & thePackage.name & """@en ;" & vbCrLf
	objOTLFile.WriteText "	dc:description ""Ontology for " & thePackage.Name & ", derived from the UML model""@en ." & vbCrLf
	objOTLFile.WriteText vbCrLf
end sub

sub coreClasses
'Create core classes for the ontology
	'---------------------------------------------------------------------------------------------------
	'Root class
	objOTLFile.WriteText "### " & owlURI & "#" & coreClass & vbCrLf
	objOTLFile.WriteText ":" & coreClass &  " a owl:Class ;" & vbCrLf
	objOTLFile.WriteText "         owl:disjointUnionOf ( :" & strPrefix & "Feature :" & strPrefix & "CodeList :" & strPrefix & "Enumeration :" & strPrefix & "DataType" & " ) ;" & vbCrLf 		
	objOTLFile.WriteText "         rdfs:label """ & rootTitle & " Root""@en ." & vbCrLf 	
	'TN-ITS Feature as subtype of ISO 19109 AnyFeature and GeoSPARQL Feature
	objOTLFile.WriteText "### " & owlURI & "#Feature" & vbCrLf
	objOTLFile.WriteText ":" & strPrefix & "Feature" &  " a owl:Class ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:subClassOf <http://def.isotc211.org/iso19109/2015/GeneralFeatureModel#AnyFeature> ," & vbCrLf
    objOTLFile.WriteText  "                          :" & coreclass & " ," & vbCrLf
    objOTLFile.WriteText  "                       gsp:Feature ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:label """ & rootTitle & " Feature""@en ." & vbCrLf 	
	strDjFeature = ":" & strPrefix & "Feature owl:disjointUnionOf ( "
	'Core class for all code values
	objOTLFile.WriteText "### " & owlURI & "#CodeList" & vbCrLf
	objOTLFile.WriteText ":" & strPrefix & "CodeList" &  " a owl:Class ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:subClassOf :" & coreClass & ", skos:Concept ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:label """ & rootTitle & " Code value""@en ." & vbCrLf 	
	strDjCode = ":" & strPrefix & "CodeList owl:disjointUnionOf ( "
	'Core class for all enumerations
	objOTLFile.WriteText "### " & owlURI & "#Enumeration" & vbCrLf
	objOTLFile.WriteText ":" & strPrefix & "Enumeration" &  " a owl:Class ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:subClassOf :" & coreClass & ", skos:Concept ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:label """ & rootTitle & " Enumeration value""@en ." & vbCrLf 					
	strDjEnum = ":" & strPrefix & "Enumeration owl:disjointUnionOf ( "
	'Core class for all datatypes
	objOTLFile.WriteText "### " & owlURI & "#DataType" & vbCrLf
	objOTLFile.WriteText ":" & strPrefix & "DataType" &  " a owl:Class ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:subClassOf :" & coreClass & " ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:label """ & rootTitle & " Data type""@en ." & vbCrLf 	
	strDjDT = ":" & strPrefix & "DataType owl:disjointUnionOf ( "
	'------------------------------------------------------------------------------------------
end sub

sub addPropertyLists
'Add attributes and associaton ends to internal property lists
	if isGlobal then
		'Add attribute to list of global properties, with information concerning global range
		Repository.WriteOutput "Script", Now & " Global property. Adding <" & propertyName & "> to the list of global property names", 0 
		if not lstGlobalPropertyNames.Contains(propertyName) then lstGlobalPropertyNames.Add propertyName, hasGlobalRange
	elseif not lstUniquePropertyNames.Contains(propertyName) then 
		'Not identified yet - add to list of unique names
		Repository.WriteOutput "Script", Now & " New property name. Adding <" & propertyName & "> to the list of unique property names", 0 
		lstUniquePropertyNames.Add propertyName, propertyName
	else	
		'Not global, but already identified - add to list of duplicate names
		Repository.WriteOutput "Script", Now & " Duplicate property name. Adding <" & propertyName & "> to the list of duplicate property names", 0 
		if not lstDuplicatePropertyNames.Contains(propertyName) then lstDuplicatePropertyNames.Add propertyName, propertyName
	end if
end sub

sub recClassList(p)
'Recusive traverse through package and create list of class and property names
	set pck = p
	Repository.WriteOutput "Script", Now & " Traversing package " & pck.Name, 0 
	'--------------------------------------------------------------------------------------------------
	'List of classes, for avoiding duplicate names on classes and properties
	for each el in pck.Elements
		if el.Type = "Class" or el.Type="Enumeration" or el.Type = "DataType" then 
			Repository.WriteOutput "Script", Now & " Adding <" & el.Name & "> to the list of classes", 0 
			lstClasses.Add UCase(el.name),el.ElementGUID
			
			if UCase(el.Stereotype) = "FEATURETYPE" or UCase(el.Stereotype) = "DATATYPE" then 
				'Lists of properties, for avoiding duplicate property names
				
				for each attr in el.Attributes 
					'Identify global properties from tagged values
					isGlobal = false
					hasGlobalRange = false		
					for each aTag in attr.TaggedValues
						if aTag.Name = "isGlobal" and aTag.Value = "true" then isglobal = true
						if aTag.Name = "hasGlobalRange" and aTag.Value = "true" then hasGlobalRange = true					
					next
					
					propertyName = attr.Name
					addPropertyLists
				next
								
				for each con in el.Connectors
					getConEnd
					if (con.type = "Aggregation" or con.Type = "Association") and conEnd.Navigable <> "Non-Navigable" and conEnd.Role <> "" then	
						isGlobal = false
						hasGlobalRange = false		
						for each rTag in conEnd.TaggedValues
							if rTag.Tag = "isGlobal" and rTag.Value = "true" then isglobal = true
							if rTag.Tag = "hasGlobalRange" and rTag.Value = "true" then hasGlobalRange = true					
						next
						propertyName = conEnd.Role
						addPropertyLists
					end if
				next
			end if
		end if	
	Next
	
	dim subP as EA.Package
	for each subP in pck.packages
	    recClassList subP 
	next
end sub 


sub createProperty
'--------------------------------------------------------------------------------
'Create property and set restrictions
	'Only for internal properties, not if hasURI = true (external properties shall not be created)
	if not hasURI then
		'Set unique property name and check whether range shall be set 
		if lstGlobalPropertyNames.Contains(propertyName) then
			'Check for global range - global properties may have different ranges for different classes
			i = lstGlobalPropertyNames.IndexofKey(propertyName)
			hasGlobalRange = lstGlobalPropertyNames.GetByIndex(i)
		elseif not lstGlobalPropertyNames.Contains(propertyName) then
			'Make sure the property name is unique
			if lstClasses.Contains(UCASE(propertyName)) or lstDuplicatePropertyNames.Contains(propertyName) then 
				'Define unique property name by adding prefix Class name + "." 
				propertyName = el.Name & "." & propertyName
			else
				hasGlobalRange = true 'All UML properties have global range by default
			end if	
		end if	
		
		'-----------------------------------------------------------------------------------------
		'Create property if not created 
		if not lstCreatedProperties.Contains(propertyName)  then
			objOTLFile.WriteText vbCrLf
			objOTLFile.WriteText "### " & owlURI & "#" & propertyName & vbCrLf
			if dt = "d" then
				Repository.WriteOutput "Script", Now & " Datatype property: " & propertyName & " , cardinality: " & lower & ".." & upper & " (Range = " & range & ")", 0 
				objOTLFile.WriteText ":" & propertyName & " rdf:type owl:DatatypeProperty ;" & vbCrLf
			else
				Repository.WriteOutput "Script", Now & " Object property: " & propertyName & " , cardinality: " & lower & ".." & upper & " (Range = " & range & ")", 0 
				objOTLFile.WriteText ":" & propertyName & " rdf:type owl:ObjectProperty ;" & vbCrLf
			end if
			'---------------------------
			'Set defintion if not empty
			if not propertyDef = "" then 
				propertyDef = replace(propertyDef, """","\""")
				propertyDef = replace(propertyDef, vbCrLf," ")	
				objOTLFile.WriteText "         skos:definition """ & propertyDef & """@en ;" & vbCrLf
			end if	
			'---------------------------
			'Set equivalence if not empty
			if not equivalentTo = "" then 
				objOTLFile.WriteText "         owl:equivalentProperty " & equivalentTo & " ;" & vbCrLf
				Repository.WriteOutput "Script", Now & " --- Equivalent to: " & equivalentTo, 0 
			end if	
			'---------------------------
			'Set domain if not global property

			if not lstGlobalPropertyNames.Contains(propertyName) then 
				objOTLFile.WriteText "         rdfs:domain :" & el.Name & ";" & vbCrLf
				Repository.WriteOutput "Script", Now & " --- Domain: " & el.Name, 0 
			end if	
			'---------------------------
			'Set range if hasGlobalRange
			if hasGlobalRange then 
				objOTLFile.WriteText "         rdfs:range " & range & ";" & vbCrLf
				Repository.WriteOutput "Script", Now & " --- Range: " & range, 0 
			end if	
			'Set functional property if cardinality = 1 and not global. 
			if (not lstGlobalPropertyNames.Contains(propertyName)) and lower = "1" and upper = "1" then 
				objOTLFile.WriteText "         rdf:type owl:FunctionalProperty;" & vbCrLf
				Repository.WriteOutput "Script", Now & " --- Functional property", 0 
			end if
			'Set inverse if inverse navigability
			if inverseProperty then 
				Repository.WriteOutput "Script", Now & " --- Inverse property", 0 
				objOTLFile.WriteText "         " & inverseStatement & " ;" & vbCrLf
				inverseProperty = false								
			end if

			'Close property statement with "."
			objOTLFile.WriteText "         rdfs:label """ & propertyName & """@en ." & vbCrLf 	
			'Add to list of created properties (only for global properties?)
			lstCreatedProperties.Add propertyName, ""
		end if
	end if
	
	if hasURI then
		propertyName = "<" & propertyName & ">" 
	else
		propertyName = ":" & propertyName
	end if
	
	'--------------------------------------------------------------------------------------------
	'Set cardinality restrictions for the property on this specific class
	if not (lower = "0" and upper = "*") then 'No cardinality requirements on 0..*
		objOTLFile.WriteText ":" & el.Name & " rdfs:subClassOf [ rdf:type owl:Restriction ;" & vbCrLf
		objOTLFile.WriteText "         owl:onProperty " & propertyName & ";" & vbCrLf 	
		if dt = "d" then
			objOTLFile.WriteText "         owl:onDataRange " & range & ";" & vbCrLf 		
		else
			objOTLFile.WriteText "         owl:onClass " & range & ";" & vbCrLf 		
		end if
		if lower = upper then 
			objOTLFile.WriteText "       owl:qualifiedCardinality """ & lower & """^^xsd:nonNegativeInteger ;" & vbCrLf 'Exact cardinality
		else
			if lower <> "0" then objOTLFile.WriteText "       owl:minQualifiedCardinality """ & lower & """^^xsd:nonNegativeInteger ;" & vbCrLf 'Lower <> 0 --> Mandatory, minimum cardinality		
			if upper <> "*" then objOTLFile.WriteText "       owl:maxQualifiedCardinality """ & upper & """^^xsd:nonNegativeInteger ;" & vbCrLf 'Upper <> * --> Restricted maximum cardinality	
		end if
		objOTLFile.WriteText "         ] ." & vbCrLf
	end if	
	'All values from
	objOTLFile.WriteText ":" & el.Name & " rdfs:subClassOf [ rdf:type owl:Restriction ;" & vbCrLf
	objOTLFile.WriteText "         owl:onProperty " & propertyName & ";" & vbCrLf 	
	objOTLFile.WriteText "         owl:allValuesFrom " & range & ";" & vbCrLf 	
	objOTLFile.WriteText "         ] ." & vbCrLf
	objOTLFile.WriteText vbCrLf
		
end sub

sub getConEnd
'Get the correct connector end and associated elements
	if con.ClientID = el.ElementID then
		set relEl = Repository.GetElementByID(con.SupplierID)
		set conEnd = con.SupplierEnd
		set conInverseEnd = con.ClientEnd
	else
		set relEl = Repository.GetElementByID(con.ClientID)
		set conEnd = con.ClientEnd
		set conInverseEnd = con.SupplierEnd
	end if 		
end sub

sub recPackageTraverse(p)
'----------------------------------------------------------------------------------------------------
'Recursive traverse through package structure
	set pck = p
	Repository.WriteOutput "Script", Now & " Traversing package " & pck.Name, 0 
	objOTLFile.WriteText vbCrLf
	'------------------------------------------------------------------------------------------------------
	for each el in pck.Elements
		'Initiate disjointUnionOf string 
		dim strDjCls
		strDjCls = 	":" & el.Name & " owl:disjointUnionOf ( "
		'------------------------------------------------------------------------------------------------------
		'Classes -- as OWL Classes
		if el.Type = "Class" or el.Type="Enumeration" or el.Type = "DataType" then 
			'Check tagged values
			equivalentTo = ""
			subclassOf = ""
			hasURI=false
			for each eTag in el.TaggedValues
				if eTag.Name = "uri" then 
					className = eTag.Value 'Defined uri for the class in the UML model
					hasURI = true
				end if	
				if eTag.Name = "equivalentTo" then
					if equivalentTo <> "" then equivalentTo = equivalentTo & ", " 
					equivalentTo = equivalentTo & "<" & eTag.Value & ">"
				end if
				if eTag.Name = "subclassOf" then
					if subclassOf <> "" then subclassOf = subclassOf & ", " 
					subclassOf = subclassOf & "<" & eTag.Value & ">"
				end if
			next
		
			'Create class
			objOTLFile.WriteText vbCrLf
			Repository.WriteOutput "Script", Now & " Element: " & el.Stereotype & " " & el.Name, 0 
			objOTLFile.WriteText "### " & owlURI & ":" & el.Name & vbCrLf
			objOTLFile.WriteText ":" & el.Name & " a owl:Class ;" & vbCrLf
			'------------------------------------------------------------------------------------------------------
			'Check whether the class is a subtype. If so, do not subtype directly under core classes
			dim subcls
			subcls = false
			For each con in el.Connectors
				if con.Type = "Generalization" and con.ClientID = el.ElementID then	subcls = true
			next	
			
			'Subclass and equivalence string from tagged value
			if subclassOf <> "" then objOTLFile.WriteText "       rdfs:subClassOf " & subclassOf & " ;" & vbCrLf	
			if equivalentTo <> "" then objOTLFile.WriteText "       owl:equivalentClass " & equivalentTo & " ;" & vbCrLf	

			'Place classes under core classes 
			if not subcls then
				if UCase(el.Stereotype) = "FEATURETYPE" then
					objOTLFile.WriteText "       rdfs:subClassOf :" & strPrefix & "Feature ;" & vbCrLf	
					strDjFeature = strDjFeature & ":" & el.Name & " "
					if not fcd = "" then objOTLFile.WriteText "          rdfs:isDefinedBy  <" & fcd & el.Name & ">;" & vbCrLf
				elseif UCase(el.Stereotype) = "CODELIST" then
					objOTLFile.WriteText "       rdfs:subClassOf :" & strPrefix & "CodeList ;" & vbCrLf	
					strDjCode = strDjCode & ":" & el.Name & " "
					if not clr = "" then 
						objOTLFile.WriteText "          rdfs:isDefinedBy  <" & clr & el.Name & ">;" & vbCrLf	
						'objOTLFile.WriteText "          owl:sameAs  <" & clr & el.Name & ">;" & vbCrLf	
					end if
				elseif UCase(el.Stereotype) = "ENUMERATION" or el.Type = "Enumeration" then			
					objOTLFile.WriteText "       rdfs:subClassOf :" & strPrefix & "Enumeration ;" & vbCrLf	
					strDjEnum = strDjEnum & ":" & el.Name & " "
					if not enr = "" then 
						objOTLFile.WriteText "          rdfs:isDefinedBy  <" & enr & el.Name & ">;" & vbCrLf
						'objOTLFile.WriteText "          owl:sameAs  <" & enr & el.Name & ">;" & vbCrLf
					end if	
				elseif UCase(el.Stereotype) = "DATATYPE" then
					objOTLFile.WriteText "       rdfs:subClassOf :" & strPrefix & "DataType ;" & vbCrLf	
					strDjDT = strDjDT & ":" & el.Name & " "
				end if
			end if	
			'------------------------------------------------------------------------------------------------------
			'Definition
			if not el.Notes = "" then 
				definition = replace(el.Notes, """","\""")
				definition = replace(definition, vbCrLf," ")	
				objOTLFile.WriteText "         skos:definition """ & definition & """@en ;" & vbCrLf
			end if	
			
			objOTLFile.WriteText "       rdfs:label """ & el.Name & """@en ." & vbCrLf 

			'---------------------------------------------------------------------------------------------------------
			'Create concept schemes for enumerations and code lists
			if UCase(el.Stereotype) = "ENUMERATION" or el.Type = "Enumeration" or UCase(el.Stereotype) = "CODELIST" then
				objOTLFile.WriteText vbCrLf
				objOTLFile.WriteText "### " & owlURI & ":" & el.Name & "Code" & vbCrLf
				objOTLFile.WriteText ":" & el.Name & "Code a skos:ConceptScheme ;" & vbCrLf		
				objOTLFile.WriteText "         skos:definition """ & definition & """@en ;" & vbCrLf
				if UCase(el.Stereotype) = "CODELIST" and not clr = "" then
						objOTLFile.WriteText "          owl:sameAs  <" & clr & el.Name & ">;" & vbCrLf	
				elseif (UCase(el.Stereotype) = "ENUMERATION" or el.Type = "Enumeration") and not enr = "" then 
						objOTLFile.WriteText "          owl:sameAs  <" & enr & el.Name & ">;" & vbCrLf
				end if	
				objOTLFile.WriteText "       dc:isFormatOf :" & el.Name & " ." & vbCrLf
			end if	
				
			'------------------------------------------------------------------------------------------------------
			'Relations - generalizations and associations
			For each con in el.Connectors
				getConEnd
				
				'------------------------------------------------------------------------------------------------------
				'Generalization - subclass axiom
				if con.Type = "Generalization" and con.ClientID = el.ElementID then
					Repository.WriteOutput "Script", Now & " Subclass of " & relEl.Name, 0 
					objOTLFile.WriteText ":" & el.Name & " rdfs:subClassOf :" & relEl.Name & " ." & vbCrLf	
				'Generalization - disjointUnionOf for the superclass
				elseif con.Type = "Generalization" and con.SupplierID = el.ElementID then
					Repository.WriteOutput "Script", Now & " Superclass for " & relEl.Name, 0 
					strDjCls = strDjCls & ":" & relEl.Name & " "
				'------------------------------------------------------------------------------------------------------
				'Associations - object properties
				elseif (con.type = "Aggregation" or con.Type = "Association") and conEnd.Navigable <> "Non-Navigable" and conEnd.Role <> "" then	
					dt = "o"
					propertyName = conEnd.Role
					propertyDef = conEnd.RoleNote
					dim crdArr
					crdArr = split(conEnd.Cardinality,"..")
					lower = crdArr(0)
					if Ubound(crdArr) = 0 then upper = lower else upper = crdArr(1)		
					if not relEl is nothing then 
						range = ":" & relEl.Name
						equivalentTo = ""
						hasURI=false
						for each rTag in conEnd.TaggedValues
							if rTag.Tag = "rangeVocabulary" then range = "<" & rTag.Value & "#" & relEl.Name & ">"
							if rTag.Tag = "rangeClass" then range = "<" & rTag.Value & ">" 
							if rTag.Tag = "uri" then 
								propertyName = rTag.Value 'Defined uri for the property in the UML model
								hasURI = true
							end if	
							if rTag.Tag = "equivalentTo" then
								if equivalentTo <> "" then equivalentTo = equivalentTo & ", " 
								equivalentTo = equivalentTo & "<" & rTag.Value & ">"
							end if
						next
						'Get other end. If navigable and with role: set owl:InverseOf
						inverseProperty = false					
						if conInverseEnd.Navigable <> "Non-Navigable" and conInverseEnd.Role <> "" then
							inverseProperty = true
							inverseStatement = "owl:inverseOf :" & conInverseEnd.Role 
							for each rTag in conInverseEnd.TaggedValues
								if rTag.Tag = "uri" then inverseStatement = inverseStatement = "owl:inverseOf <" & rTag.Value & "> " 'Defined uri for the property in the UML model
							next
						end if
						createProperty
					else
						Repository.WriteOutput "Error", Now & " Unknown type for property: " & propertyName & " , cardinality: " & lower & ".." & upper, 0 
					end if	
				end if
			next
			'-----------------------------------------------------------------------------------------------------------
			'Attributes as properties for feature types and datatypes
			if UCase(el.Stereotype) = "FEATURETYPE" or UCase(el.Stereotype) = "DATATYPE" then
				For each attr in el.Attributes
					'------------------------------------------------------------------------------
					'Find type of property (data or object) and range
					Select Case attr.Type
						Case "CharacterString","Integer","Real","Date","DateTime","Boolean","URI","Sign":
							'Datatype property, mapping to XSD Datatypes
							dt = "d"
							Select Case attr.Type
								Case "CharacterString": 
									range = "xsd:string"
								Case "Integer":
									range = "xsd:integer"							
								Case "Real":
									range = "xsd:double"
								Case "Date":
									range = "xsd:date"
								Case "DateTime":
									range = "xsd:dateTime"
								Case "Boolean":
									range = "xsd:boolean"
								Case "URI":
									range = "xsd:anyURI"
								Case "Sign":
									range = "<http://def.isotc211.org/iso19136/2007/BasicTypes#Sign>"
							End Select					
					case else
						'Object Property (name and definition)
						dt = "o"
						if not attr.ClassifierID = 0 then 
							'Find related element
							set relEl = Repository.GetElementByID(attr.ClassifierID)
							range = ":" & relEl.Name
							'Hardcoded references - should be configurable in mapping file, as for ShapeChange
							select case attr.Type
								case "CI_Citation"
									'Hardcoded reference to the 19115 ontology
									range = "<http://def.isotc211.org/iso19115/2003/CitationAndResponsiblePartyInformation#CI_Citation>"
								case "TM_Period"
									'Hardcoded reference to the 19103 ontology
									range = "<http://def.isotc211.org/iso19108/2006/TemporalObjects#TM_Period>"					
								case "Measure"
									'Hardcoded reference to the 19103 ontology
									range = "<http://def.isotc211.org/iso19103/2015/MeasureTypes#Measure>"					
								case "Distance"
									'Hardcoded reference to the 19103 ontology
									range = "<http://def.isotc211.org/iso19103/2015/MeasureTypes#Distance>"					
								case "Length"
									'Hardcoded reference to the 19103 ontology
									range = "<http://def.isotc211.org/iso19103/2015/MeasureTypes#Length>"					
								case "Velocity"				
									'Hardcoded reference to the 19103 ontology
									range = "<http://def.isotc211.org/iso19103/2015/MeasureTypes#Velocity>"					
								case "GM_Point"				
									'Hardcoded reference to GeoSPARQL
									range = "<http://www.opengis.net/ont/sf#Point>"					
								case "GM_Curve"				
									'Hardcoded reference to GeoSPARQL
									range = "<http://www.opengis.net/ont/sf#Curve>"					
								case "GM_Surface"				
									'Hardcoded reference to GeoSPARQL
									range = "<http://www.opengis.net/ont/sf#Surface>"					
									
							End select
							'For external classes: Get URI from attribute tag rangeVocabulary or rangeClass
							equivalentTo = ""
							hasURI = false
							for each aTag in attr.TaggedValues
								if aTag.Name = "rangeVocabulary" then range = "<" & aTag.Value & "#" & relEl.Name & ">" 'Defined vocalublary for the range class in the UML model
								if aTag.Name = "rangeClass" then range = "<" & aTag.Value & ">" 'Defined class as range in the UML model
								if aTag.Name = "uri" then 
									propertyName = aTag.Value 'Defined uri for the property in the UML model
									hasURI = true
								end if	
								if aTag.Name = "equivalentTo" then
									if equivalentTo <> "" then equivalentTo = equivalentTo & ", " 
								equivalentTo = equivalentTo & "<" & aTag.Value & ">"
								end if
							next	
						else
							dt = "-"
						end if	
					End Select	
					
					if not hasURI then propertyName = attr.Name
					propertyDef = attr.Notes
					lower = attr.LowerBound
					upper = attr.UpperBound
					if not dt = "-" then 
						createProperty
					else
						Repository.WriteOutput "Error", Now & " Unknown type for property: " & propertyName & " , cardinality: " & lower & ".." & upper, 0 
					end if
				next
			end if 
			
			'----------------------------------------------------------------------------------------------------------
			'Codelist or enumeration values - instances of classes
			if 	UCase(el.Stereotype) = "CODELIST" or UCase(el.Stereotype) = "ENUMERATION" or el.Type = "Enumeration" then
				'Initiate oneOf statement
				oneOfEnum = ":" & el.Name & " owl:oneOf ( " 
				For each attr in el.Attributes
					'Include value in oneOf-statement 
					oneOfEnum = oneOfEnum & ":" & el.Name & "." & attr.Name & " "
					objOTLFile.WriteText vbCrLf
					objOTLFile.WriteText "### " & owlURI & ":" & el.Name & "." & attr.Name & vbCrLf
					'objOTLFile.WriteText ":" & el.Name & "." & attr.Name & " a :" & el.Name & " ;" & vbCrLf
					objOTLFile.WriteText ":" & el.Name & "." & attr.Name & " a :" & el.Name & ",skos:Concept ;" & vbCrLf
					objOTLFile.WriteText "         skos:inScheme :" &  el.Name & "Code ;" & vbCrLf					
					if not attr.Notes = "" then 
						definition = replace(attr.Notes, """","\""")
						definition = replace(definition, vbCrLf," ")	
						objOTLFile.WriteText "         skos:definition """ & definition & """@en ;" & vbCrLf
					end if	
					if 	UCase(el.Stereotype) = "CODELIST" and not clr = "" then 
						objOTLFile.WriteText "          owl:sameAs  <" & clr & el.Name & "/" & attr.Name & ">;" & vbCrLf
						objOTLFile.WriteText "          rdfs:isDefinedBy  <" & clr & el.Name & "/" & attr.Name & ">;" & vbCrLf
					elseif 	(UCase(el.Stereotype) = "ENUMERATION" or el.Type = "Enumeration") and not enr = "" then 
						objOTLFile.WriteText "          owl:sameAs  <" & enr & el.Name & "/" & attr.Name & ">;" & vbCrLf
						objOTLFile.WriteText "          rdfs:isDefinedBy  <" & enr & el.Name & "/" & attr.Name & ">;" & vbCrLf
					end if	

					objOTLFile.WriteText "         rdfs:label """ & attr.Name & """@no ." & vbCrLf					
				next	
				'Close and write oneOf statement 
				oneOfEnum = oneOfEnum & " ) ; ." 
				if 	(UCase(el.Stereotype) = "ENUMERATION" or el.Type = "Enumeration") and InStr(oneOfEnum,"owl:oneOf (  )") = 0 then objOTLFile.WriteText oneOfEnum & vbCrLf			
			end if
		end if
		'Close and write non-empty disjoint union strings for classes
		strDjCls = strDjCls & " ) ; ."
		if 	InStr(strDjCls,"owl:disjointUnionOf (  )") = 0 then objOTLFile.WriteText strDjCls & vbCrLf	
	next
	

	dim subP as EA.Package
	for each subP in pck.packages
	    recPackageTraverse subP
	next
	
end sub

sub main
	'Script tabs
	Repository.EnsureOutputVisible "Script"
	Repository.ClearOutput "Script"
	Repository.CreateOutputTab "Error"
	Repository.ClearOutput "Error"
	Repository.CreateOutputTab "OWL"
	Repository.ClearOutput "OWL"

	set thePackage = Repository.GetTreeSelectedPackage
		
	if thePackage is nothing then
		Repository.WriteOutput "Error", Now & " No selected package", 0 
		exit sub
	end if
	
	'Find package tags for URI, namespace abbreviation etc
	owlURI = ""
	strPrefix = ""
	rootTitle = ""
	creator = ""
	fcd = ""
	Repository.WriteOutput "Script", Now & " Main package: " & thePackage.Name, 0 
	for each eTag in thePackage.Element.TaggedValues
		Repository.WriteOutput "Script", Now & " Tag: " & eTag.Name & " value: " & eTag.Value, 0 
		if eTag.Name = "owlNamespace" then owlURI = eTag.Value
		If eTag.Name = "xmlns" then strPrefix = eTag.Value
		If eTag.Name = "rootTitle" then rootTitle = eTag.Value
		if eTag.Name = "creator" then creator = eTag.Value
		if eTag.Name = "fcd" then fcd = eTag.Value
		if eTag.Name = "clr" then clr = eTag.Value
		if eTag.Name = "enr" then enr = eTag.Value		
	next
	If owlURI = "" or strPrefix = "" or rootTitle = "" or creator = "" then 
		Repository.WriteOutput "Error", Now & " Missing main package tag", 0 
		exit sub
	end if

	'---------------------------------------------------------------------
	'Create text stream
	Set objFSO=CreateObject("Scripting.FileSystemObject")
	Set objOTLFile = CreateObject("ADODB.Stream")
	objOTLFile.CharSet = "utf-8"
	objOTLFile.Open
	
	'dim filetime
	'filetime = replace(Now, ".","")
	'filetime = replace(filetime, ":","")
	'filetime = replace(filetime, " ","_")
	
	'---------------------------------------------------------------------
	'Create ontology with prefixes, imports and core classes
	Repository.WriteOutput "Script", Now & " Creating ontology with prefixes, imports and core classes...", 0 
	coreClass = strPrefix 
	heading
	coreClasses	
	
	'---------------------------------------------------------------------
	'Create internal lists of classes and properties
	Repository.WriteOutput "Script", Now & " ----------------------------------------------",0
	Repository.WriteOutput "Script", Now & " Creating internal lists of classes and properties...", 0 
	Set lstOP = CreateObject("System.Collections.SortedList")
	Set lstDP = CreateObject("System.Collections.SortedList")
	Set lstClasses = CreateObject("System.Collections.SortedList")
	Set lstUniquePropertyNames = CreateObject("System.Collections.SortedList")
	Set lstDuplicatePropertyNames = CreateObject("System.Collections.SortedList")
	Set lstGlobalPropertyNames = CreateObject("System.Collections.SortedList")
	Set lstCreatedProperties = CreateObject("System.Collections.SortedList")
	'Loop through packages, classes and properties
	recClassList thePackage
	
	'Documentation of global and dupliacte properties
	Repository.WriteOutput "Script", Now & " ----------------------------------------------",0
	Repository.WriteOutput "Script", Now & " Global properties:",0
	for i = 0 To lstGlobalPropertyNames.Count - 1
		Repository.WriteOutput "Script", Now & " " & lstGlobalPropertyNames.GetKey(i) & " (hasGlobalRange = " & lstGlobalPropertyNames.GetByIndex(i) & ")",0
	next
	Repository.WriteOutput "Script", Now & " ----------------------------------------------",0
	Repository.WriteOutput "Script", Now & " Duplicate property names:",0
	for i = 0 To lstDuplicatePropertyNames.Count - 1
		Repository.WriteOutput "Script", Now & " " & lstDuplicatePropertyNames.GetKey(i) ,0
	next
		
	'---------------------------------------------------------------------
	'Loop through packages and create classes and properties
	Repository.WriteOutput "Script", Now & " ----------------------------------------------",0
	recPackageTraverse thePackage
		
	'---------------------------------------------------------------------
	'Close and write disjoint union strings 
	strDjFeature = strDjFeature & "    ) ; ."
	objOTLFile.WriteText strDjFeature & vbCrLf	
	'No disjoint union for code lists, as a value may be relevant in several code lists
	'strDjCode = strDjCode & "    ) ; ."
	'objOTLFile.WriteText strDjCode & vbCrLf	
	strDjEnum = strDjEnum & "    ) ; ."
	objOTLFile.WriteText strDjEnum & vbCrLf	
	strDjDT = strDjDT & "    ) ; ."
	objOTLFile.WriteText strDjDT & vbCrLf	
	
	'---------------------------------------------------------------------
	'Write to file
	dim fn
	'filename = owlPath & "\" & filetime & "_" & filename & ".ttl"
	fn = owlPath & "\" & strPrefix & "-owl.ttl"
	If objFSO.FileExists(fn) then objFSO.DeleteFile fn, true
	Repository.WriteOutput "Script", Now & " Writing to file " & fn, 0 
	objOTLFile.SaveToFile fn, 2
	objOTLFile.Close
	
	Repository.WriteOutput "Script", Now & " Done. Check the Error tab", 0 
	Repository.EnsureOutputVisible "Script"


end sub

main