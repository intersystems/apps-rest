/// This class is internal to AppS.REST; consumers should not use or reference it directly.
Class AppS.REST.Model.ResourceMapProjection Extends %Projection.AbstractProjection [ System = 3 ]
{

ClassMethod CreateProjection(classname As %String, ByRef parameters As %String, modified As %String, qstruct) As %Status
{
	// Skip abstract classes.
	If $$$comClassKeyGet(classname,$$$cCLASSabstract) {
		Quit $$$OK
	}
	Set sc = $$$OK
	Try {
		Set resourceName = $Parameter(classname,"RESOURCENAME")
		Set mediaType = $Parameter(classname,"MEDIATYPE")
		
		// For each resource, there is exactly one Proxy class per mediaType.
		// Therefore, if we already have a mapping for this resourceName and mediaType, make sure
		// the classname of the class we're compiling matches what we have on record for this (resourceName, mediaType) pair.
		If ##class(AppS.REST.ResourceMap).ModelClassExists(classname,.id) {
			Set map = ##class(AppS.REST.ResourceMap).%OpenId(id,,.sc)
			If (map.ResourceName '= resourceName) || (map.MediaType '= mediaType) {
				Set sc = ##class(AppS.REST.ResourceMap).%DeleteId(id)
				$$$ThrowOnError(sc)
			}
		}
		If ##class(AppS.REST.ResourceMap).IDKEYExists(resourceName,mediaType,.id) {
			Set map = ##class(AppS.REST.ResourceMap).%OpenId(id,,.sc)
			$$$ThrowOnError(sc)
			If map.ModelClass '= classname {
				Set sc = $$$ERROR($$$GeneralError,$$$FormatText("Resource '%1', media type '%2' is already in use by class %3",resourceName,mediaType,map.ModelClass))
				$$$ThrowStatus(sc)
			}
		} Else {
			// If we don't yet have a mapping for this (resourceName, mediaType) pair, create one and populate its fields appropriately
			Set map = ##class(AppS.REST.ResourceMap).%New()
		}
		Set map.ResourceName = resourceName
		Set map.MediaType = mediaType
		Set map.ModelClass = classname
		$$$ThrowOnError(map.%Save())
	} Catch e {
		Set sc = e.AsStatus()
	}
	Quit sc
}

ClassMethod RemoveProjection(classname As %String, ByRef parameters As %String, recompile As %Boolean, modified As %String, qstruct) As %Status
{
	Set sc = $$$OK
	// Don't actually remove if it's a recompile and the class still has the projection
	// (This avoids interruption in API availability during compilation.)
	Set remove = '(recompile && ..ClassHasThisProjection(classname))
	If remove {
		If ##class(AppS.REST.ResourceMap).ModelClassExists(classname,.id) {
			Set sc = ##class(AppS.REST.ResourceMap).%DeleteId(id)
		}
	}
	Quit sc
}

/// Helper method to determine if the class supplied has this projection in its current definition
/// (*NOT* compiled class metadata, as that has not yet been updated when RemoveProjection is run)
ClassMethod ClassHasThisProjection(classname As %Dictionary.CacheClassname) As %Boolean
{
	// At this stage, assume the class definition is up-to-date,
	// but the compiled class metadata is not yet.
	Set found = 0

	// Find defined projections:
	Set projection = ""
	For {
		Set projection = $$$defMemberNext(classname,$$$cCLASSprojection,projection)
		If (projection = "") {
			Quit
		}
		If $$$defMemberKeyGet(classname,$$$cCLASSprojection,projection,$$$cPROJtype) = $ClassName() {
			Set found = 1
		}
	}
	
	If 'found {
		// Find inherited projections:
		Set supers = $ListFromString($$$defClassKeyGet(classname,$$$cCLASSsuper))
		Set pointer = 0
		While $ListNext(supers,pointer,super) {
			Set found = found || ..ClassHasThisProjection(super)
			If (found) {
				Quit
			}
		}
	}

	Quit found
}

}
