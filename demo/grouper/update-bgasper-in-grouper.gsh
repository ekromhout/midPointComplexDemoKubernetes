
def add(gs,groupName,subject) {
	GroupFinder.findByName(gs, groupName, true).addMember(subject, false)
}

gs = GrouperSession.startRootSession()

def bgasper = SubjectFinder.findById('bgasper', 'user', 'ldap')
add(gs, 'ref:affiliation:alum_excludes', bgasper)
add(gs, 'ref:affiliation:faculty_includes', bgasper)
add(gs, 'app:mailinglist:chess', bgasper)
add(gs, 'app:mailinglist:idm-fans', bgasper)
add(gs, 'test:volunteers', bgasper)
