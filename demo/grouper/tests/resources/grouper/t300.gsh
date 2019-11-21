System.out.println("************** t300.gsh starting **************");

gs = GrouperSession.startRootSession()

exportedGroups = GroupFinder.findByName(gs, 'etc:exportedGroups')
alumSubject = SubjectFinder.findByIdentifier('ref:affiliation:alum', 'group', 'g:gsa')
exportedGroups.addMember(alumSubject, false)

alumIncludes = GroupFinder.findByName(gs, 'ref:affiliation:alum_includes')
testGroup = GroupFinder.findByName(gs, 'etc:testGroup')
wprice = SubjectFinder.findById('wprice', 'person', 'ldap')
alumIncludes.addMember(wprice, false)
testGroup.addMember(wprice, false)

System.out.println("************** t300.gsh done **************");
