Include %occInclude

/// Use or operation of this code is subject to acceptance of the license available in the code repository for this code.
/// This class contains a method to generate data for Sample package
Class UnitTest.AppS.REST.Sample.Data.Utils
{

/// Invoke this method to set up the data for these classes.
/// Create one company for every five people.
ClassMethod Generate(personCount As %Integer = 100)
{
    // Make sure we always have at least 1 person
    if (personCount < 1) {
        set personCount=1
    }
        
    // Never use %KillExtent() in a real application
    do ##class(UnitTest.AppS.REST.Sample.Data.Company).%KillExtent()
    do ##class(UnitTest.AppS.REST.Sample.Data.Person).%KillExtent()
    do ##class(UnitTest.AppS.REST.Sample.Data.Employee).%KillExtent()
    //do ##class(Sample.Vendor).%KillExtent() ; doesn't work with %Storage.SQL
	kill ^Sample.DataD,^Sample.VendorI,^Sample.VendorD // VendorD has the index counter - want to restart at 1.
    
    set companyCount= personCount \ 5
    if (companyCount < 1) {
        set companyCount=1
    }

    do ##class(UnitTest.AppS.REST.Sample.Data.Company).Populate(companyCount)
	do ##class(UnitTest.AppS.REST.Sample.Data.Person).Populate(personCount)
	do ##class(UnitTest.AppS.REST.Sample.Data.Employee).Populate(personCount,,,,2)
	do ##class(UnitTest.AppS.REST.Sample.Data.Vendor).Populate(personCount)
	
	// Specify values for stream properties in Sample.Employee
	// do this for the first lucky 10 employees, for reasons of space
	
	set e1=personCount+1 ; ID of the first employee
	for i=e1:1:e1+9 {
		set employee=##class(UnitTest.AppS.REST.Sample.Data.Employee).%OpenId(i)
		set firstname=$PIECE(employee.Name,",",2)
		set firstname=$PIECE(firstname," ",1)
		set text=firstname_" used to work at "_##class(%PopulateUtils).Company()
		         _" as a(n) "_##class(%PopulateUtils).Title()
		         
		do employee.Notes.Write(text)
		
		// Add a stock picture (yes, all these employees look alike)
		do employee.Picture.Write($System.Encryption.Base64Decode(
			"iVBORw0KGgoAAAANSUhEUgAAABIAAAARCAIAAABfOGuuAAAAK3RFWHRDcmVhdGlvbiBUaW1lAFRo"_
			"dSA2IEphbiAyMDExIDE2OjIwOjU4IC0wNTAw73VlcAAAAAd0SU1FB9sBBhUWCKSIbF4AAAAJcEhZ"_
			"cwAACxIAAAsSAdLdfvwAAAAEZ0FNQQAAsY8L/GEFAAAC1klEQVR42l2TyW/TQBSHZ7MdO3HsZmub"_
			"tKnUTaWlKggEhwoJOCAh9W/ljjhxAEERbWmhFaVruiXYbpw43sYzHhyo2N5tpPfNfPq9edB1XfBv"_
			"CQGYEClgEEAEEIYIwv9aAPn7wAXwKLcSZidRhK9kFNRIroTKGjIVLP9N/8FiDo+9dJdefOODTlBN"_
			"MFCQO19s3ZaVYtIw0fyoVpUw/geLGdiyo3fBJa+2GNZVovth3YnmfbaLzA/TeP3k+mKRPWoW6wSj"_
			"G4yn4ND1Xtq7tGLN5+vjuAkU7ZMn7Qjk0LGDRJspxGp4+LFNVbw2ppcz2SHaC5P19n6PbFVMboDK"_
			"glRZyuWbCtQIZ0hcc8VLSQ4ODu3XO1dfKGcZgrLcOp6353x1qR0kkZs6nTi2YuhSGFMEOIQCHThn"_
			"b1utIOltnzh9f4gRxkXb7bcHXUuGzrlSkUunsiIhdhYC2xcRSFJGnU4TWflxbS/wW5YbVoo5wpjo"_
			"9lLnfMrrjTJzqquVLxSIcUzTLKeEoYhxRbNLNWiDVFjWteP6YtIkAAIey0lXSXxCYxGP+EH2WBZX"_
			"KlKW5KTew5nO4yVvAtq9LnmR2Qs6lCQYFBVZiiQQXwmaJoMRkJfBEEsh9RpTGyuFzhiEqQ8vLS5x"_
			"tVRQsySJRFC9pEwaoaG+DXjx8HQp4qbASHCOmQvI/h6xNlxRkYTncQ1NVkZ0COFwbhM19eGcfjQI"_
			"pMJJaF8ffZ7hQR6wNGXRaUd2jXzk4ca01xgtP19ZNgq5m3EbuvRgYfb0zaIVOM2x47DrXu7WWNvI"_
			"PL3vWiJrmo5E1Vy4s3z31pws4xsMITjbrK7Rp6822Ym/XTZZqHKey0yRLBFZwmZZWV1Yenb/3i/D"_
			"P38yu2NxukHgk/fbo5vn3zlJ6IjIdkZVSb2u373XWF2dmxwvDQP8WfD3vnHOgyDoe77jDKyO3+/H"_
			"CAHDUKo1vVTSi0VNVVWE0K/mHyUqfH/CYKtlAAAAAElFTkSuQmCC"))
		
		do employee.%Save()
	}
}

}
