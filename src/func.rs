use std::sync::Mutex;
#[cfg(test)]
use rocket;
use rocket::State;
use rocket_contrib::Json;
use data::{Data, Poll};
use characters::*;


#[derive(Deserialize)]
struct StartPollInput {
    number: isize,
    title: String,
    questions: String,
}

#[derive(Serialize)]
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
    let StartPollInput{number, mut title, questions}=start_poll_input.into_inner();
    title.make_ascii_lowercase();
    let free_answers=questions.len()==0;
    let mut questions=questions
    .lines()
    .map(|l| {
        let mut l=l.to_string();
        l.make_ascii_lowercase();
        l
    })
    .filter(|s| (*s).len()!=0)
    .collect::<Vec<String>>();
    questions.sort_unstable();
    questions.dedup();

    if number < 2 || number > 20{
        return StartPollOutput::err("Number must be between 2 and 20.")
    }

    if title.len() < 3 || title.len() > 32 || !contains_only(title.as_str(), LOWER_ALPHANUMERIC_SYMBOLS_CHARS){
        return StartPollOutput::err("Title length must be between 3 and 32 characters long and only contain alphanumeric or these `!? ,;.:-_()[]{}&%$` characters.")
    }

    if !free_answers && (questions.len() < 3 || questions.len() > 1000){
        return StartPollOutput::err("There must be between 3 and 1000 unique questions.")
    }

    if questions.iter().any(|q| (*q).len() < 3 || (*q).len() > 50 || !contains_only((*q).as_str(), LOWER_ALPHA_SPACE_CHARS)){
        return StartPollOutput::err("The length of each question must be between 3 and 50, and only contain letters and spaces.")
    }

    match data.lock() {
        Err(_) => StartPollOutput::err("Server error."),
        Ok(mut data) => {
            let poll=Poll{number: number, title: title, questions: questions, answers: vec![]};
            StartPollOutput::ok(data.add_poll(poll))
        },
    }
}

#[derive(Serialize)]
struct GetPollOutput {
    title: String,
    questions: Vec<String>,
    polls_filled: usize,
    polls_number: isize,
    error: &'static str,
}

impl GetPollOutput {
    fn err(error: &'static str) -> Json<GetPollOutput>{
        Json(GetPollOutput{
            title: String::new(),
            questions: Vec::new(),
            polls_filled: 0,
            polls_number: 0,
            error: error,
        })
    }
}

#[get("/get_poll/<poll_id>")]
fn get_poll(mut poll_id: String, data: State<Mutex<Data>>) -> Json<GetPollOutput>{
    poll_id.make_ascii_lowercase();

    match data.lock() {
        Err(_) => GetPollOutput::err("Server error."),
        Ok(data) => match data.get_poll(&poll_id) {
            None => GetPollOutput::err("A poll with that id does not exists."),
            Some(poll) => {
                Json(
                    GetPollOutput{
                        title: poll.title.clone(),
                        polls_filled: poll.answers.len(),
                        polls_number: poll.number,
                        questions: poll.questions.clone(),
                        error: "",
                    }
                )
            },
        },
    }
}

#[derive(Deserialize)]
struct FillPollInput {
    user_name: String,
    poll_id: String,
    answers: Vec<isize>,
}

#[post("/fill_poll", format = "application/json", data = "<fill_poll_input>")]
fn fill_poll(data: State<Mutex<Data>>, fill_poll_input: Json<FillPollInput>) -> Json<&str>{
    let mut fill_poll_input=fill_poll_input.into_inner();
    fill_poll_input.user_name.make_ascii_lowercase();
    let FillPollInput{user_name, poll_id, answers}=fill_poll_input;

    if user_name.len() < 3 || user_name.len() > 32 || !contains_only(user_name.as_str(), LOWER_ALPHA_CHARS){
        return Json("User name length must be between 3 and 32 characters long and only contain letters.")
    }

    if answers.iter().all(|x| (*x)==0){
        return Json("At least one of the categories must be agreed with.")
    }

    if !answers.iter().all(|x| (*x)==0 || (*x)==1 || (*x)==2){
        return Json("An answer must be given to each category.")
    }

    match data.lock() {
        Err(_) => Json("Server error."),
        Ok(mut data) => match data.get_poll_mut(&poll_id) {
            None => Json("A poll with that id does not exists."),
            Some(mut poll) => {
                if poll.answers.len()>=poll.number as usize{
                    Json("This poll has already been filled by the required amount of users.")
                } else if poll.answers.iter().any(|a| (*a).0==user_name){
                    Json("A user with that name has already answered the poll.")
                } else if poll.questions.len()!=answers.len(){
                    Json("The number of poll questions and answers is different.")
                } else {
                    let answers=answers.into_iter()
                    .map(|a| if a==2 {"y".to_string()} else if a==1 {"o".to_string()} else {"n".to_string()})
                    .collect::<Vec<String>>();

                    poll.answers.push((user_name, answers));
                    Json("")
                }
            },
        },
    }
}

#[derive(Deserialize)]
struct FillFreeEntryPollInput {
    user_name: String,
    poll_id: String,
    answers: String,
}

#[post("/fill_free_entry_poll", format = "application/json", data = "<fill_free_entry_poll_input>")]
fn fill_free_entry_poll(data: State<Mutex<Data>>, fill_free_entry_poll_input: Json<FillFreeEntryPollInput>) -> Json<&str>{
    let mut fill_free_entry_poll_input=fill_free_entry_poll_input.into_inner();
    fill_free_entry_poll_input.user_name.make_ascii_lowercase();
    fill_free_entry_poll_input.poll_id.make_ascii_lowercase();
    let FillFreeEntryPollInput{user_name, poll_id, answers}=fill_free_entry_poll_input;
    let mut answers=answers
    .lines()
    .map(|l| {
        let mut l=l.to_string();
        l.make_ascii_lowercase();
        l
    })
    .filter(|s| (*s).len()!=0)
    .collect::<Vec<String>>();
    answers.sort_unstable();
    answers.dedup();

    if user_name.len() < 3 || user_name.len() > 32 || !contains_only(user_name.as_str(), LOWER_ALPHA_CHARS){
        return Json("User name length must be between 3 and 32 characters long and only contain letters.")
    }

    if answers.len() < 2 || answers.len() > 1000{
        return Json("There must be between 2 and 1000 unique answers.")
    }

    if answers.iter().any(|a| (*a).len() < 3 || (*a).len() > 50 || !contains_only((*a).as_str(), LOWER_ALPHA_SPACE_CHARS)){
        return Json("The length of each answer must be between 3 and 50, and only contain letters and spaces.")
    }

    match data.lock() {
        Err(_) => Json("Server error."),
        Ok(mut data) => match data.get_poll_mut(&poll_id) {
            None => Json("A survey with that token does not exists."),
            Some(mut poll) => {
                if poll.answers.len()>=poll.number as usize{
                    Json("This survey has already been filled by the required amount of users.")
                } else if poll.answers.iter().any(|a| (*a).0==user_name){
                    Json("A user with that name has already answered the survey.")
                } else if poll.questions.len()!=0{
                    Json("This survey is not a free entry survey.")
                } else {
                    poll.answers.push((user_name, answers));
                    Json("")
                }
            },
        },
    }
}

#[derive(Serialize)]
struct GetPollResultsOutput {
    title: String,
    user_names: Vec<String>,
    all_yay: Vec<String>,
    all_open: Vec<String>,
    error: String,
}

impl GetPollResultsOutput {
    fn err<T: Into<String>>(error: T) -> Json<GetPollResultsOutput>{
        Json(GetPollResultsOutput{
            title: String::new(),
            user_names: Vec::new(),
            all_yay: Vec::new(),
            all_open: Vec::new(),
            error: error.into(),
        })
    }
}

#[get("/get_poll_results/<poll_id>")]
fn get_poll_results(poll_id: String, data: State<Mutex<Data>>) -> Json<GetPollResultsOutput>{
    let mut result_template=GetPollResultsOutput{title: "".into(), user_names: vec![], all_yay: vec![], all_open: vec![], error: String::new()};
    match data.lock() {
        Err(_) => GetPollResultsOutput::err("Server error."),
        Ok(data) => match data.get_poll(&poll_id) {
            None => GetPollResultsOutput::err("A survey with that id does not exists."),
            Some(poll) => {
                result_template.title=poll.title.clone();
                result_template.user_names=poll.answers.iter().map(|x| (*x).0.clone()).collect::<Vec<String>>();
                if poll.answers.len() < poll.number as usize || poll.answers.len() < 2{
                    GetPollResultsOutput::err(format!("This survey needs {} responses, but it only has {}.", poll.number, poll.answers.len()))
                }
                else if poll.questions.is_empty(){
                    match poll.answers.split_first() {
                        None => GetPollResultsOutput::err("Server error."),
                        Some((head, tail)) => {
                            result_template.all_yay=head.1.iter()
                            .filter(|q| tail.iter().all(|tq| (*tq).1.contains(q)))
                            .cloned()
                            .collect::<Vec<String>>();

                            Json(result_template)
                        },
                    }
                } else {
                    if !poll.answers.iter().all(|a| (*a).1.len()==poll.questions.len()){
                        GetPollResultsOutput::err("Server error.")
                    } else{
                        result_template.all_yay=poll.questions.iter()
                        .enumerate()
                        .filter(|ia| poll.answers.iter().all(|a| a.1[ia.0]=="y"))
                        .map(|ia| ia.1)
                        .cloned()
                        .collect::<Vec<String>>();

                        result_template.all_open=poll.questions.iter()
                        .enumerate()
                        .filter(|ia| !poll.answers.iter().all(|a| a.1[ia.0]=="y"))
                        .filter(|ia| poll.answers.iter().all(|a| a.1[ia.0]!="n"))
                        .map(|ia| ia.1)
                        .cloned()
                        .collect::<Vec<String>>();

                        Json(result_template)
                    }
                }
            },
        },
    }
}

// // Black box only
// #[cfg(test)]
// mod tests {
//     use super::*;
//     use rocket::local::Client;
//     use rocket::http::Status;
//     use rocket::http::ContentType;
//     use std::sync::Mutex;
//     use serde_json;

//     // Mock struct so I don't have to deal with static lifetimes
//     #[derive(Serialize, Deserialize)]
//     struct StartPollOutput {
//         poll_id: String,
//         error: String,
//     }

//     #[test]
//     fn start_poll() {
//         fn call(client: &Client, input: StartPollInput) -> (Status,Option<StartPollOutput>){
//             let mut response=client
//                 .post("start_poll")
//                 .header(ContentType::JSON)
//                 .body(json!(input).to_string())
//                 .dispatch();

//             let output=response
//                 .body_string()
//                 .and_then(|body| serde_json::from_str(body.as_str()).ok());

//             return (response.status(), output)
//         }

//         fn check(output: (Status, Option<StartPollOutput>), expect: bool, error_message: &'static str){
//             let (status, output)=output;
//             assert_eq!(status, Status::Ok);
//             assert!(output.is_some());
//             let output=output.unwrap();
//             if expect{
//                 assert!(output.error=="", error_message);
//                 assert!(output.poll_id.len()==(64/8)*2, error_message);
//             } else {
//                 assert!(output.error!="", error_message);
//                 assert!(output.poll_id.len()==0, error_message);
//             }

//         }

//         fn input_with_number(number: isize) -> StartPollInput{
//             StartPollInput{
//                 number: number,
//                 title: String::from("Title"),
//                 questions: String::from("question a\nquestion b\nquestion c"),
//             }
//         }

//         fn input_with_title(title: &str) -> StartPollInput{
//             StartPollInput{
//                 number: 2,
//                 title: String::from(title),
//                 questions: String::from("question a\nquestion b\nquestion c"),
//             }
//         }

//         fn input_with_questions(questions: &str) -> StartPollInput{
//             StartPollInput{
//                 number: 2,
//                 title: String::from("title"),
//                 questions: String::from(questions),
//             }
//         }

//         let data=Data::new();
//         let rocket = rocket::ignite()
//             .manage(Mutex::new(data))
//             .mount("/", routes![start_poll]);
//         let client = Client::new(rocket).expect("valid rocket instance");


//         // Arguments within ranges should work
//         let output=call(&client, input_with_number(2));
//         check(output, true, "min poll number of 2 does not work");

//         let output=call(&client, input_with_number(20));
//         check(output, true, "max poll number of 20 does not work");

//         let output=call(&client, input_with_title("ttt"));
//         check(output, true, "min title length of 3 does not work");

//         let output=call(&client, input_with_title("tttttttttttttttttttttttttttttttt"));
//         check(output, true, "max title length of 32 does not work");

//         let output=call(&client, input_with_questions(""));
//         check(output, true, "empty question string should be allowed; it is not");

//         // Arguments outside ranges should not work
//         let output=call(&client, input_with_number(1));
//         check(output, false, "min poll number of 2 not enforced");

//         let output=call(&client, input_with_number(21));
//         check(output, false, "max poll number of 20 not enforced");

//         let output=call(&client, input_with_title("tt"));
//         check(output, false, "min title length of 3 not enforced");

//         let output=call(&client, input_with_title("ttttttttttttttttttttttttttttttttz"));
//         check(output, false, "max title length of 32 not enforced");

//         let output=call(&client, input_with_questions("question a\nquestion b\nquestion b"));
//         check(output, false, "min questions of 3 not enforced");


//         // Just some tests with invalid characters
//         let output=call(&client, input_with_questions("question3a\nquestion b\nquestion c"));
//         check(output, false, "no numbers in questions not enforced");

//         let output=call(&client, input_with_questions("question_a\nquestion b\nquestion c"));
//         check(output, false, "no simbols in questions not enforced");

//         // Just some tests potentially problematic characters
//         let output=call(&client, input_with_questions("question<a\nquestion b\nquestion c"));
//         check(output, false, "problematic character allowed in question");
//         let output=call(&client, input_with_questions("question>a\nquestion b\nquestion c"));
//         check(output, false, "problematic character allowed in question");

//         let output=call(&client, input_with_questions("title<"));
//         check(output, false, "problematic character allowed in title");
//         let output=call(&client, input_with_questions("title>"));
//         check(output, false, "problematic character allowed in title");
//     }
// }