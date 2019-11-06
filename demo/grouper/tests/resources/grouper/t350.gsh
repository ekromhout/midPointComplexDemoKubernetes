System.out.println("************** t350.gsh starting **************");

gs = GrouperSession.startRootSession()

alumIncludes = GroupFinder.findByName(gs, 'ref:affiliation:alum_includes')
testGroup = GroupFinder.findByName(gs, 'midpoint:test')
kwhite = SubjectFinder.findById('kwhite', 'person', 'ldap')
wprice = SubjectFinder.findById('wprice', 'person', 'ldap')
testGroup.addMember(kwhite, false)
alumIncludes.deleteMember(wprice, false)

System.out.println("************** t350.gsh done **************");
