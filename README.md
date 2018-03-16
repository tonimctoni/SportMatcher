# SportMatcher

Web application for finding common interests in sport.

# TODO

 - Report can be a String of ABCs (or YON), standing for Yay, Open, Nope.

 - Userid 1 is admin.

 - Add unique constraint and autoincrement to DB if possible.

 - Use get_checked instead of get for sqlite operations.

 - Add some backend error handling (mostly just logging).

 - Sanitize everything comming from the client.

 - Use a hash function designed to hash passwords.

 - When logging out, reset nav state.

 - Since there is no session token, maybe cache recently used `(nick+pass)->id`. Maybe use queue to manage "recently used".

 - Do not require credentials if not necesary (like for getting plugin names, or plugins themselves).

 - Rethink when data should be sent to the client (that is, when the client should request it).

 - On credentialized requests return Options, such that wrong credentials yield `None` from server.

 - Backend is inefficient: String allocations everywhere. Maybe try to mend this. Maybe use `RawStr` where possible.

 - Possible pitfall: Filling may some times (and some times not) be sorted.