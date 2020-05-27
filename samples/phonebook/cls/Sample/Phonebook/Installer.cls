Class Sample.Phonebook.Installer Extends %ZPM.AbstractInstaller
{

ClassMethod OnConfigureComponent(pNamespace As %String, pVerbose As %Boolean = 0, ByRef pVars) As %Status
{
    Set sc = $$$OK
    Try {
        If pVerbose {
            Write !,"[Sample.Phonebook.Installer:OnConfigureComponent] Populating sample data... "
        }
        $$$ThrowOnError(##class(Sample.Phonebook.Model.Person).%KillExtent())
        $$$ThrowOnError(##class(Sample.Phonebook.Model.Person).Populate(100))
        $$$ThrowOnError(##class(Sample.Phonebook.Model.PhoneNumber).Populate(300))
        If pVerbose {
            Write "done."
        }
    } Catch e {
        Set sc = e.AsStatus()
        If pVerbose {
            Write "An error occurred: ",$System.Status.GetErrorText(sc)
        }
    }
	Quit sc
}

}
