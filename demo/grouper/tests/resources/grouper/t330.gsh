System.out.println("************** t330.gsh starting **************");

gs = GrouperSession.startRootSession()

testGroup = GroupFinder.findByName(gs, 'midpoint:test')
alumIncludesGroup = GroupFinder.findByName(gs, 'ref:affiliation:alum_includes')
wprice = SubjectFinder.findById('wprice', 'person', 'ldap')
testGroup.addMember(wprice, false)
alumIncludesGroup.addMember(wprice, false)

System.out.println("************** t330.gsh done **************");
