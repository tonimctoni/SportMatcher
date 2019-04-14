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

#[test]
fn api() {
    let data=data::Data::new();

    let rocket=rocket::ignite()
    .manage(Mutex::new(data))
    .mount("/api/", routes![func::put_poll, func::get_poll, func::post_poll]);

    let client = Client::new(rocket).expect("valid rocket instance");

    let valid_inputs=[
        (2, "title", ""),
        (20, "title", ""),
        (2, "abcdefghijklmnopqrstuvwxyzabcdef", ""),
        (2, "title[]{}(),.-;:_", ""),
        (2, "title", "question1\nquestion2\nquestion3\n"),
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