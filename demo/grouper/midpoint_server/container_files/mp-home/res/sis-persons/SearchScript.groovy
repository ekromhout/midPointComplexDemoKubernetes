/* 
 * ====================
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
 * 
 * Copyright 2013 ForgeRock. All rights reserved.
 * 
 * The contents of this file are subject to the terms of the Common Development
 * and Distribution License("CDDL") (the "License").  You may not use this file
 * except in compliance with the License.
 * 
 * You can obtain a copy of the License at
 * http://opensource.org/licenses/cddl1.php
 * See the License for the specific language governing permissions and limitations
 * under the License.
 * 
 * When distributing the Covered Code, include this CDDL Header Notice in each file
 * and include the License file at http://opensource.org/licenses/cddl1.php.
 * If applicable, add the following below this CDDL Header, with the fields
 * enclosed by brackets [] replaced by your own identifying information:
 * "Portions Copyrighted [year] [name of copyright owner]"
 * ====================
 * Portions Copyrighted 2013 ConnId.
 */

import groovy.sql.Sql
import groovy.sql.DataSet
import org.identityconnectors.framework.common.objects.*

// Parameters:
// The connector sends the following:
// connection: handler to the SQL connection
// objectClass: a String describing the Object class (__ACCOUNT__ / __GROUP__ / other)
// action: a string describing the action ("SEARCH" here)
// log: a handler to the Log facility
// options: a handler to the OperationOptions Map
// query: a handler to the Query Map
//
// The Query map describes the filter used.
//
// query = [ operation: "CONTAINS", left: attribute, right: "value", not: true/false ]
// query = [ operation: "ENDSWITH", left: attribute, right: "value", not: true/false ]
// query = [ operation: "STARTSWITH", left: attribute, right: "value", not: true/false ]
// query = [ operation: "EQUALS", left: attribute, right: "value", not: true/false ]
// query = [ operation: "GREATERTHAN", left: attribute, right: "value", not: true/false ]
// query = [ operation: "GREATERTHANOREQUAL", left: attribute, right: "value", not: true/false ]
// query = [ operation: "LESSTHAN", left: attribute, right: "value", not: true/false ]
// query = [ operation: "LESSTHANOREQUAL", left: attribute, right: "value", not: true/false ]
// query = null : then we assume we fetch everything
//
// AND and OR filter just embed a left/right couple of queries.
// query = [ operation: "AND", left: query1, right: query2 ]
// query = [ operation: "OR", left: query1, right: query2 ]
//
// Returns: A list of Maps. Each map describing one row.
// !!!! Each Map must contain a '__UID__' and '__NAME__' attribute.
// This is required to build a ConnectorObject.

log.info("Entering "+action+" Script");

def sql = new Sql(connection);
def result = []
def where = "";
def sqlParams = null

switch ( objectClass ) {
    case "__ACCOUNT__":

    uidColumn = 'uid'
    nameColumn = 'uid'

    log.info("Building where clause, query {0}, uidcolumn {1}, nameColumn {2}", query, uidColumn, nameColumn)

    String left = query?.get("left")
    if (left != null) {
      if (Uid.NAME.equals(left)) {
          left = uidColumn
      } else if (Name.NAME.equals(left)) {
          left = nameColumn
      }

      String right = query.get("right")

      String operation = query.get("operation")
      switch (operation) {
          case "CONTAINS":
              right = '%' + right + '%'
              break;
          case "ENDSWITH":
              right = '%' + right
              break;
          case "STARTSWITH":
              right = right + '%'
              break;
      }

      sqlParams = [:]
      sqlParams.put(left, right)
      right = ":" + left

      def engine = new groovy.text.SimpleTemplateEngine()

      def whereTemplates = [
            CONTAINS          : ' $left ${not ? "not " : ""}like $right',
            ENDSWITH          : ' $left ${not ? "not " : ""}like $right',
            STARTSWITH        : ' $left ${not ? "not " : ""}like $right',
            EQUALS            : ' $left ${not ? "<>" : "="} $right',
            GREATERTHAN       : ' $left ${not ? "<=" : ">"} $right',
            GREATERTHANOREQUAL: ' $left ${not ? "<" : ">="} $right',
            LESSTHAN          : ' $left ${not ? ">=" : "<"} $right',
            LESSTHANOREQUAL   : ' $left ${not ? ">" : "<="} $right'
      ]

      def wt = whereTemplates.get(operation)
      if (wt != null) {
        def binding = [left: left, right: right, not: query.get("not")]
        def template = engine.createTemplate(wt).make(binding)
        where = ' where ' + template.toString()
        log.info("Where clause: {0}, with parameters {1}", where, sqlParams)
      } else {
        log.warn('Unsupported query: {0}, continuing without WHERE clause (worsening the performance)', query)
        sqlParams = null
        where = ''
      }
    }

    q = 'select uid, surname, givenName, fullName, mail from SIS_PERSONS' + where

    log.info('query = {0}', query)
    log.info('sql = {0}', q)
    log.info('sqlParams = {0}', sqlParams)
   
    def processRow = { row -> result.add([
	__UID__:row.uid, 
	__NAME__:row.uid, 
	uid:row.uid,
	surname:row.surname,
	givenName:row.givenName,
	fullName:row.fullName,
	mail:row.mail])
    }

    if (sqlParams != null) {
      sql.eachRow(sqlParams, q, processRow)
    } else {
      sql.eachRow(q, processRow)
    }
    break

    default:
    result;
}

return result;
