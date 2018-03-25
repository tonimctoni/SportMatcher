# SportMatcher

Web application for finding common interests in sport.

# Notes

 - Empty questions field means poll with free entries.

 - Internally, all text is lower case.

# Todo

 - There might be integer overflow bugs. Also narrowing bugs. Fix them.

 - Add explanation of input fields somewhere.

 - Replace `poll` for `survey` and `name` for `survey token` in the frontend and strings sent to the frontend.

 - Make `number` not only the minimum amount of answers, but also the maximum. Do necesary renames for this.

# Frontend Design

    - Navbar has 4 options:
        - Greeting
            - Does nothing, just looks nice.
        - Start poll
            - Button for poll with predefined questions. Button for poll with free entries.
            - Field for name: Only those who know the name may join. (Must be unique. Add button to check if already exists).
            - Field for number of responders needed for result to be seen.
            - Field for title: Hopefully descriptive title for poll.
            - If predefined questions: Text entry for questions: Newline separated entries.
            - If predefined questions: Some predefined questionnaires: Click to auto fill entry for questions (and maybe title).
        - Fill poll
            - Initial state:
                - Field for poll name.
                - Ok button.
            - Poll name was selected state (and the name exists).
                - Show poll title
                - Input field for responder's name.
                - If predefined questions: Questions, with buttons to select answer.
                - Else: Text entry for responses: Newline separated entries.
                - Button to submit responses.
        - See poll results
            - Initial state:
                - Field for poll name.
                - Ok button.
            - Poll name was selected state (and the name exists).
                - Results are shown if enough responders have responded.

# Backend Design

    - Poll struct:
        - Number
        - Title
        - Questions
        - Answers

    - Poll map: Name -> Poll

    - Fn start_poll

    - Fn poll_name_exists

    - Fn has_name_answered_poll

    - Fn get_poll (if exists)

    - Fn fill_poll (receives array of nums e {0,1,2}) (and name)

    - Fn fill_free_entry_poll (receives array of strings) (and name)

    - Fn get_poll_results