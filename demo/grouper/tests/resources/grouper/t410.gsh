System.out.println("************** t410.gsh starting **************");

gs = GrouperSession.startRootSession()

testGroup = GroupFinder.findByName(gs, 'midpoint:test')
kwhite = SubjectFinder.findById('kwhite', 'person', 'ldap')
wprice = SubjectFinder.findById('wprice', 'person', 'ldap')
testGroup.deleteMember(kwhite, false)
testGroup.deleteMember(wprice, false)

System.out.println("************** t410.gsh done **************");
