# SportMatcher

Web application for finding common interests in "sport".

# Notes

 - Empty questions field means poll with free entries.

 - Internally, all text is lower case.

# Todo

 - There might be integer conversion bugs, like narrowing bugs. Fix them.

 - Add explanation of input fields somewhere.

 - See if DOS attacks can be mitigated somehow. Right now it should be easy for an attacker to arbitrarily enlarge the `polls` hash map.

 - Take a look at cost/benefit of making frontend nicer.

# Backend Api

 - PUT /api/poll -> Create survey

 - GET /api/poll/<poll_id> -> Retrieve survey

 - POST /api/poll/<poll_id> -> Add entry to survey