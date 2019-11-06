System.out.println("************** initialize.gsh starting...")

gs = GrouperSession.startRootSession()

addStem("", "app", "app")
addStem("", "basis", "basis")
addStem("", "bundle", "bundle")
addStem("", "org", "org")
addStem("", "test", "test")
addStem("", "midpoint", "midpoint")

addRootStem("ref", "ref")
addStem("ref", "course", "course")
addStem("ref", "affiliation", "affiliation")

group = GroupFinder.findByName(gs, "etc:sysadmingroup", true)
group.getAttributeDelegate().assignAttribute(LoaderLdapUtils.grouperLoaderLdapAttributeDefName()).getAttributeAssign()
attributeAssign = group.getAttributeDelegate().retrieveAssignment(null, LoaderLdapUtils.grouperLoaderLdapAttributeDefName(), false, true)
attributeAssign.getAttributeValueDelegate().assignValue(LoaderLdapUtils.grouperLoaderLdapQuartzCronName(), "0 * * * * ?")
attributeAssign.getAttributeValueDelegate().assignValue(LoaderLdapUtils.grouperLoaderLdapTypeName(), "LDAP_SIMPLE")
attributeAssign.getAttributeValueDelegate().assignValue(LoaderLdapUtils.grouperLoaderLdapFilterName(), "(cn=sysadmingroup)")
attributeAssign.getAttributeValueDelegate().assignValue(LoaderLdapUtils.grouperLoaderLdapSearchDnName(), "ou=midpoint,ou=Groups")
attributeAssign.getAttributeValueDelegate().assignValue(LoaderLdapUtils.grouperLoaderLdapServerIdName(), "demo")
attributeAssign.getAttributeValueDelegate().assignValue(LoaderLdapUtils.grouperLoaderLdapSourceIdName(), "ldap")
attributeAssign.getAttributeValueDelegate().assignValue(LoaderLdapUtils.grouperLoaderLdapSubjectExpressionName(), '${loaderLdapElUtils.convertDnToSpecificValue(subjectId)}')
attributeAssign.getAttributeValueDelegate().assignValue(LoaderLdapUtils.grouperLoaderLdapSubjectAttributeName(), "uniqueMember")
attributeAssign.getAttributeValueDelegate().assignValue(LoaderLdapUtils.grouperLoaderLdapSubjectIdTypeName(), "subjectId")

midpointGroupsGroup = new GroupSave(gs).assignName("etc:midpointGroups").assignCreateParentStemsIfNotExist(true).save()

testGroup = new GroupSave(gs).assignName("midpoint:test").assignCreateParentStemsIfNotExist(true).save()
chess = new GroupSave(gs).assignName("app:mailinglist:chess").assignCreateParentStemsIfNotExist(true).save()
idmfans = new GroupSave(gs).assignName("app:mailinglist:idm-fans").assignCreateParentStemsIfNotExist(true).save()
cs = new GroupSave(gs).assignName("app:cs").assignCreateParentStemsIfNotExist(true).save()
volunteers = new GroupSave(gs).assignName("test:volunteers").assignCreateParentStemsIfNotExist(true).save()

midpointGroupsGroup.addMember(SubjectFinder.findById(testGroup.getId(), 'group', 'g:gsa'), false)
midpointGroupsGroup.addMember(SubjectFinder.findById(chess.getId(), 'group', 'g:gsa'), false)
midpointGroupsGroup.addMember(SubjectFinder.findById(idmfans.getId(), 'group', 'g:gsa'), false)
midpointGroupsGroup.addMember(SubjectFinder.findById(cs.getId(), 'group', 'g:gsa'), false)
midpointGroupsGroup.addMember(SubjectFinder.findById(volunteers.getId(), 'group', 'g:gsa'), false)

System.out.println("************** initialize.gsh done.")
