use rocket::http::ContentType;
use rocket::local::Client;
use rocket::http::Status;
use std::sync::Mutex;
use data;
use func;
use serde_json::json;

#[derive(Serialize)]
struct StartPollInput {
    number: isize,
    title: String,
    questions: String,
}

#[derive(Deserialize)]
pub struct StartPollOutput {
    poll_id: String,
    error: String,
}

fn put(client: &Client, input: StartPollInput) -> (Status, StartPollOutput){
    let mut response=client.put("/api/poll")
    .header(ContentType::JSON)
    .body(json!(input).to_string())
    .dispatch();

    let status=response.status();
    assert_eq!(response.content_type().expect("Expected content type"), ContentType::JSON);
    let body=response.body_string().expect("Expected body string");
    let output=serde_json::from_str(body.as_str()).expect("Could not parse struct from body string");

    (status, output)
}

#[derive(Deserialize)]
struct PollQuestions {
    title: String,
    questions: Vec<String>,
    polls_filled: usize,
    polls_number: isize,
}

#[derive(Deserialize)]
struct PollAnswers {
    title: String,
    user_names: Vec<String>,
    all_yay: Vec<String>,
    all_open: Vec<String>,
}

#[derive(Deserialize)]
pub struct GetPollOutput{
    questions: Option<PollQuestions>,
    answers: Option<PollAnswers>,
    error: String,
}

fn get<T: AsRef<str>>(client: &Client, poll_id: T) -> (Status, GetPollOutput){
    let mut response=client.get(format!("/api/poll/{}", poll_id.as_ref()))
    .dispatch();

    let status=response.status();
    let output=if Status::Ok==status{
        assert_eq!(response.content_type().expect("Expected content type"), ContentType::JSON);
        let body=response.body_string().expect("Expected body string");
        serde_json::from_str(body.as_str()).expect("Could not parse struct from body string")
    } else{
        GetPollOutput{questions: None, answers: None, error: String::new()}
    };

    (status, output)
}

#[derive(Serialize)]
pub struct FillPollInput {
    user_name: String,
    fixed_answers: Option<Vec<isize>>,
    free_answers: Option<String>,
}

fn post<T: AsRef<str>>(client: &Client, poll_id: T, input: FillPollInput) -> (Status, String){
    let mut response=client.post(format!("/api/poll/{}", poll_id.as_ref()))
    .header(ContentType::JSON)
    .body(json!(input).to_string())
    .dispatch();

    let status=response.status();
    let output=if Status::Ok==status{
        assert_eq!(response.content_type().expect("Expected content type"), ContentType::JSON);
        let body=response.body_string().expect("Expected body string");
        serde_json::from_str(body.as_str()).expect("Could not parse struct from body string")
    } else{
        String::new()
    };

    (status, output)
}

#[test]
fn api_put() {
    let data=data::Data::new();

    let rocket=rocket::ignite()
    .manage(Mutex::new(data))
    .mount("/api/", routes![func::put_poll]);

    let client = Client::new(rocket).expect("valid rocket instance");

    let valid_inputs=[
        (2, "title", ""),
        (20, "title", ""),
        (2, "abcdefghijklmnopqrstuvwxyzabcdef", ""),
        (2, "title[]{}(),.-;:_", ""),
        (2, "title", "question1\nquestion2\nquestion3\n\n\n"),
        (2, "title", "[]{\n}(),\n.-;\n:_!"),
    ].into_iter()
    .map(|(n,t,q)| (n, String::from(*t), String::from(*q)))
    .map(|(n,t,q)| StartPollInput{number: *n, title: t, questions: q})
    .collect::<Vec<_>>();

    let invalid_inputs=[
        (1, "title", ""),
        (21, "title", ""),
        (2, "title<", ""),
        (2, "ti", ""),
        (2, "title", "question1"),
        (2, "title", "question1\n"),
        (2, "title", "question1\nquestion2\nquestion2\n"),
        (2, "title", "question1\nquestion2\nqu\n"),
        (2, "title", "question1\nquestion2\nquestion<3>\n"),
    ].into_iter()
    .map(|(n,t,q)| (n, String::from(*t), String::from(*q)))
    .map(|(n,t,q)| StartPollInput{number: *n, title: t, questions: q})
    .collect::<Vec<_>>();


    for input in valid_inputs{
        let (status, StartPollOutput{poll_id, error})=put(&client, input);
        assert_eq!(status, Status::Ok);
        assert!(poll_id!="");
        assert!(error=="");
    }

    for input in invalid_inputs{
        let (status, StartPollOutput{poll_id, error})=put(&client, input);
        assert_eq!(status, Status::Ok);
        assert!(poll_id=="");
        assert!(error!="");
    }
}


#[test]
fn api_get_post() {
    let data=data::Data::new();

    let rocket=rocket::ignite()
    .manage(Mutex::new(data))
    .mount("/api/", routes![func::put_poll, func::get_poll, func::post_poll]);

    let client = Client::new(rocket).expect("valid rocket instance");

    // Get requests with invalid ids
    let (status, _)=get(&client, "");
    assert_ne!(status, Status::Ok);

    let (status, output)=get(&client, "ABCDEF");
    assert_eq!(status, Status::Ok);
    assert!(output.questions.is_none());
    assert!(output.answers.is_none());
    assert!(output.error!="");

    // Post requests with invalid ids
    let (status, _)=post(&client, "", FillPollInput{user_name: String::from("name"), fixed_answers: None, free_answers: Some(String::from("abc\ndef\nhij\n"))});
    assert_ne!(status, Status::Ok);

    // FREE POLL
    // start free poll
    let (status, StartPollOutput{poll_id,..})=put(&client, StartPollInput{number: 2, title: String::from("title"), questions: String::new()});
    assert_eq!(status, Status::Ok);

    // get freshly started free poll
    let (status, output)=get(&client, &poll_id);
    assert_eq!(status, Status::Ok);
    assert!(output.answers.is_none());
    assert!(output.error=="");
    let questions=output.questions.expect("Expected questions");
    assert_eq!(questions.title, "title");
    assert_eq!(questions.questions, Vec::new() as Vec<String>);
    assert_eq!(questions.title, "title");
    assert_eq!(questions.polls_filled, 0);
    assert_eq!(questions.polls_number, 2);

    let invalid_inputs=[
        ("a", None, Some(String::from("abc\ndef\nhij\n"))),
        ("namea", None, Some(String::from("abc\n\n"))),
        ("nameb", None, Some(String::from("abc\ndef\nhij<script>\n"))),
        ("namec", None, Some(String::from("abc\nabc\nabc\n"))),
        ("named", Some(vec![1,2,3]), None),
    ].iter().map(|(a,b,c)| FillPollInput{user_name: String::from(*a), fixed_answers: b.clone(), free_answers: c.clone()}).collect::<Vec<_>>();


    for input in invalid_inputs{
        let (status, error)=post(&client, &poll_id, input);
        assert_eq!(status, Status::Ok);
        assert!(error!="");
    }


    let (status, error)=post(&client, &poll_id, FillPollInput{user_name: String::from("Namee"), fixed_answers: None, free_answers: Some(String::from("abc\ndef\nhij\n"))});
    assert_eq!(status, Status::Ok);
    assert!(error=="");

    let (status, error)=post(&client, &poll_id, FillPollInput{user_name: String::from("Namee"), fixed_answers: None, free_answers: Some(String::from("abc\ndef\nhij\n"))});
    assert_eq!(status, Status::Ok);
    assert!(error!="");

    let (status, error)=post(&client, &poll_id, FillPollInput{user_name: String::from("namef"), fixed_answers: None, free_answers: Some(String::from("abc\n\n\nK LM\n"))});
    assert_eq!(status, Status::Ok);
    assert!(error=="");

    let (status, error)=post(&client, &poll_id, FillPollInput{user_name: String::from("nameg"), fixed_answers: None, free_answers: Some(String::from("abc\ndef\nhij\n"))});
    assert_eq!(status, Status::Ok);
    assert!(error!="");

    let (status, output)=get(&client, &poll_id);
    assert_eq!(status, Status::Ok);
    assert!(output.questions.is_none());
    assert!(output.error=="");
    let answers=output.answers.expect("Expected answers");
    assert_eq!(answers.title, "title");
    assert_eq!(answers.user_names, vec!["namee", "namef"]);
    assert_eq!(answers.all_yay, vec!["abc"]);
    assert_eq!(answers.all_open, vec![] as Vec<&str>);

    // FIXED POLL
}
