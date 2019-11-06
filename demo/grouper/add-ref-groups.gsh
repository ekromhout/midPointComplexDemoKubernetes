
def addGroups(gs,stem,owner,regexp) {
	for (group in stem.childGroups) {
		if (!group.name.endsWith('_includes') &&
		    !group.name.endsWith('_excludes') &&
		    !group.name.endsWith('_systemOfRecord') &&
		    !group.name.endsWith('_systemOfRecordAndIncludes') &&
		    (regexp == null || group.extension ==~ regexp)) {
			println 'Adding: ' + group
			def s = SubjectFinder.findById(group.getId(), 'group', 'g:gsa')
			owner.addMember(s, false)
		} else {
			println 'Ignoring: ' + group
		}
	}
}

gs = GrouperSession.startRootSession()
def supergroup = GroupFinder.findByName(gs, "etc:midpointGroups", true)
def cs = GroupFinder.findByName(gs, "app:cs", true)

addGroups(gs, StemFinder.findByName(gs, 'ref:affiliation'), supergroup, null)
addGroups(gs, StemFinder.findByName(gs, 'ref:dept'), supergroup, null)
addGroups(gs, StemFinder.findByName(gs, 'ref:course'), supergroup, null)

addGroups(gs, StemFinder.findByName(gs, 'ref:course'), cs, /CS.*/)
