# CouchDB

## Securing your CouchDB to the hostile internet!

When creating a database, you *absolutely must* add at least one user the the "_security" endpoint of that database. Otherwise the database is considered *PUBLIC* and anyone including anonymous users will be able to read/write to it!

### Create a user for John Doe
```bash
curl -XPUT -vu admin:secret http://localhost:5984/_users/org.couchdb.user:john -H 'Content-Type: application/json' -d '{"_id": "org.couchdb.user:john","name": "John Doe","roles":["write", "delete"], "type":"user","password":"changeme"}'
```

### Create a dabase for John Doe

```bash
curl -XPUT -vu admin:secret http://localhost:5984/john-database
curl -XPUT -vu admin:secret http://localhost:5984/john-database/_security -H 'Content-Type: application/json' -d '{"admins":{"names":[],"roles":[]}, "members":{"names":["john"],"roles":["john-database"]}}'
```

### Hardening the security using a validate_doc_update design document

The following design document does the following:

- The SERVER admins (e.g. user with the role '_admin') can do anything.
- The users added as "admins" to the _security endpoint of this database or all users with the role "admin" can read/write/delete all documents and *design* documents.
- The users added as "members" to the _security endpoint of this database can all read all documents.
- The users added as "members" to the _security endpoint of this database and that have "write" or "john-database-write" role can all create/update all documents except design docs.
- The users added as "members" to the _security endpoint of this database and that have "delete" or "john-database-delete" role can delete all documents except desing doc.
    

```bash
curl -XPUT -vu admin:secret http://localhost:5984/john-database/_design/security -H 'Content-Type: application/json' -d '{"_id": "_design/security","language": "javascript","validate_doc_update": "function(newDoc, oldDoc, userCtx, secObj){if(userCtx.roles.indexOf(\"_admin\") >= 0) return;if (userCtx.roles.indexOf(\"admin\") < 0) {if(newDoc._deleted && userCtx.roles.indexOf(\"delete\") < 0 && userCtx.roles.indexOf(\"delete-\" + userCtx.db) < 0) throw({\"forbidden\": \"You do not have delete permission.\"});if(userCtx.roles.indexOf(\"write\") < 0 && userCtx.roles.indexOf(\"write-\" + userCtx.db) < 0) throw({\"forbidden\": \"You do not have write permission.\"});}}"}'
```

