use std::sync::Mutex;
#[cfg(test)]
use rocket;
use rocket::State;
use rocket_contrib::Json;
use data::{Data, Poll};
use characters::*;


#[derive(Serialize, Deserialize)]
struct StartPollInput {
    poll_number: isize,
    poll_title: String,
    poll_questions: String,
}

#[derive(Serialize, Deserialize)]
struct StartPollOutput {
    poll_id: String,
    error: &'static str,
}

impl StartPollOutput {
    fn ok(poll_id: String) -> Json<StartPollOutput>{
        Json(StartPollOutput{
            poll_id: poll_id,
            error: "",
        })
    }

    fn err(error: &'static str) -> Json<StartPollOutput>{
        Json(StartPollOutput{
            poll_id: String::new(),
            error: error,
        })
    }
}

#[post("/start_poll", format = "application/json", data = "<start_poll_input>")]
fn start_poll(data: State<Mutex<Data>>, start_poll_input: Json<StartPollInput>) -> Json<StartPollOutput>{
    let StartPollInput{poll_number, mut poll_title, poll_questions}=start_poll_input.into_inner();
    poll_title.make_ascii_lowercase();
    let free_answers=poll_questions.len()==0;
    let mut poll_questions=poll_questions
    .lines()
    .map(|l| {
        let mut l=l.to_string();
        l.make_ascii_lowercase();
        l
    })
    .filter(|s| (*s).len()!=0)
    .collect::<Vec<String>>();
    poll_questions.sort_unstable();
    poll_questions.dedup();

    if poll_number < 2 || poll_number > 20{
        return StartPollOutput::err("Number must be between 2 and 20.")
    }

    if poll_title.len() < 3 || poll_title.len() > 32 || !contains_only(poll_title.as_str(), LOWER_ALPHANUMERIC_SYMBOLS_CHARS){
        return StartPollOutput::err("Title length must be between 3 and 32 characters long and only contain alphanumeric or these `!? ,;.:-_()[]{}&%$` characters.")
    }

    if !free_answers && (poll_questions.len() < 3 || poll_questions.len() > 1000){
        return StartPollOutput::err("There must be between 3 and 1000 unique questions.")
    }

    if poll_questions.iter().any(|q| (*q).len() < 3 || (*q).len() > 50 || !contains_only((*q).as_str(), LOWER_ALPHA_SPACE_CHARS)){
        return StartPollOutput::err("The length of each question must be between 3 and 50, and only contain letters and spaces.")
    }

    match data.lock() {
        Err(_) => StartPollOutput::err("Server error."),
        Ok(mut data) => {
            let poll=Poll{number: poll_number, title: poll_title, questions: poll_questions, answers: vec![]};
            StartPollOutput::ok(data.add_poll(poll))
        },
    }
}

// Black box only
#[cfg(test)]
mod tests {
    use super::*;
    use rocket::local::Client;
    use rocket::http::Status;
    use rocket::http::ContentType;
    use std::sync::Mutex;
    use serde_json;

    // Mock struct so I don't have to deal with static lifetimes
    #[derive(Serialize, Deserialize)]
    struct StartPollOutput {
        poll_id: String,
        error: String,
    }

    #[test]
    fn start_poll() {
        fn call(client: &Client, input: StartPollInput) -> (Status,Option<StartPollOutput>){
            let mut response=client
                .post("start_poll")
                .header(ContentType::JSON)
                .body(json!(input).to_string())
                .dispatch();

            let output=response
                .body_string()
                .and_then(|body| serde_json::from_str(body.as_str()).ok());

            return (response.status(), output)
        }

        fn check(output: (Status, Option<StartPollOutput>), expect: bool, error_message: &'static str){
            let (status, output)=output;
            assert_eq!(status, Status::Ok);
            assert!(output.is_some());
            let output=output.unwrap();
            if expect{
                assert!(output.error=="", error_message);
                assert!(output.poll_id.len()==(64/8)*2, error_message);
            } else {
                assert!(output.error!="", error_message);
                assert!(output.poll_id.len()==0, error_message);
            }

        }

        fn input_with_number(number: isize) -> StartPollInput{
            StartPollInput{
                poll_number: number,
                poll_title: String::from("Title"),
                poll_questions: String::from("question a\nquestion b\nquestion c"),
            }
        }

        fn input_with_title(title: &str) -> StartPollInput{
            StartPollInput{
                poll_number: 2,
                poll_title: String::from(title),
                poll_questions: String::from("question a\nquestion b\nquestion c"),
            }
        }

        fn input_with_questions(questions: &str) -> StartPollInput{
            StartPollInput{
                poll_number: 2,
                poll_title: String::from("title"),
                poll_questions: String::from(questions),
            }
        }

        let data=Data::new();
        let rocket = rocket::ignite()
            .manage(Mutex::new(data))
            .mount("/", routes![start_poll]);
        let client = Client::new(rocket).expect("valid rocket instance");


        // Arguments within ranges should work
        let output=call(&client, input_with_number(2));
        check(output, true, "min poll number of 2 does not work");

        let output=call(&client, input_with_number(20));
        check(output, true, "max poll number of 20 does not work");

        let output=call(&client, input_with_title("ttt"));
        check(output, true, "min title length of 3 does not work");

        let output=call(&client, input_with_title("tttttttttttttttttttttttttttttttt"));
        check(output, true, "max title length of 32 does not work");

        let output=call(&client, input_with_questions(""));
        check(output, true, "empty question string should be allowed; it is not");

        // Arguments outside ranges should not work
        let output=call(&client, input_with_number(1));
        check(output, false, "min poll number of 2 not enforced");

        let output=call(&client, input_with_number(21));
        check(output, false, "max poll number of 20 not enforced");

        let output=call(&client, input_with_title("tt"));
        check(output, false, "min title length of 3 not enforced");

        let output=call(&client, input_with_title("ttttttttttttttttttttttttttttttttz"));
        check(output, false, "max title length of 32 not enforced");

        let output=call(&client, input_with_questions("question a\nquestion b\nquestion b"));
        check(output, false, "min questions of 3 not enforced");


        // Just some tests with invalid characters
        let output=call(&client, input_with_questions("question3a\nquestion b\nquestion c"));
        check(output, false, "no numbers in questions not enforced");

        let output=call(&client, input_with_questions("question_a\nquestion b\nquestion c"));
        check(output, false, "no simbols in questions not enforced");

        // Just some tests potentially problematic characters
        let output=call(&client, input_with_questions("question<a\nquestion b\nquestion c"));
        check(output, false, "problematic character allowed in question");
        let output=call(&client, input_with_questions("question>a\nquestion b\nquestion c"));
        check(output, false, "problematic character allowed in question");

        let output=call(&client, input_with_questions("title<"));
        check(output, false, "problematic character allowed in title");
        let output=call(&client, input_with_questions("title>"));
        check(output, false, "problematic character allowed in title");
    }
}