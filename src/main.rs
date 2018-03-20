#![feature(plugin)]
#![feature(custom_derive)]
#![plugin(rocket_codegen)]
extern crate rocket;
// #[macro_use]
extern crate rocket_contrib;
#[macro_use]
extern crate serde_derive;
use std::collections::HashMap;
use std::io;
use std::path::{Path, PathBuf};
// use std::fs::File;
use std::sync::Mutex;
use rocket::response::NamedFile;
// use std::io::prelude::*;
// use rocket::http::RawStr;
use rocket::State;
use rocket_contrib::Json;
// use rocket::response::Redirect;
// use rocket::request::Form;

const LOWER_ALPHA_SPACE_CHARS: &str = "abcdefghijklmnopqrstuvwxyz ";
const LOWER_ALPHANUMERIC_CHARS: &str = "abcdefghijklmnopqrstuvwxyz0123456789";
const LOWER_ALPHANUMERIC_SYMBOLS_CHARS: &str = "abcdefghijklmnopqrstuvwxyz0123456789!? ,;.:-_()[]{}&%$";

fn contains_only(s: &str, chars: &str) -> bool{
    s.chars().all(|c| chars.chars().any(|ac| ac==c))
}

struct Poll {
    number: isize,
    title: String,
    questions: Vec<String>,
    answers: Vec<(String, Vec<String>)>,
}

#[get("/")]
fn index() -> io::Result<NamedFile> {
    NamedFile::open("frontend/index.html")
}

#[get("/<file..>")]
fn files(file: PathBuf) -> Option<NamedFile> {
    NamedFile::open(Path::new("resources/").join(file)).ok()
}

#[post("/poll_name_exists", format = "application/json", data = "<name>")]
fn poll_name_exists(polls: State<Mutex<HashMap<String, Poll>>>, name: Json<String>) -> Json<bool>{
    let mut name=name.into_inner();
    name.make_ascii_lowercase();
    match polls.lock() {
        Err(_) => Json(true),
        Ok(polls) => Json(polls.contains_key(&name)),
    }
}

#[derive(Serialize, Deserialize, Debug)]
struct ReceivedPoll {
    name: String,
    number: isize,
    title: String,
    questions: Vec<String>,
}

#[post("/start_poll", format = "application/json", data = "<received_poll>")]
fn start_poll(polls: State<Mutex<HashMap<String, Poll>>>, received_poll: Json<ReceivedPoll>) -> Json<&str>{
    let mut received_poll=received_poll.into_inner();
    received_poll.name.make_ascii_lowercase();
    received_poll.title.make_ascii_lowercase();
    for q in received_poll.questions.iter_mut(){
        (*q).make_ascii_lowercase();
    }

    if received_poll.name.len() < 3 || received_poll.name.len() > 32 || !contains_only(received_poll.name.as_str(), LOWER_ALPHANUMERIC_CHARS){
        return Json("Name length must be between 3 and 32 characters long and only contain alphanumeric characters.")
    }

    if received_poll.number < 1 || received_poll.number > 1000{
        return Json("Number must be between 1 and 1000.")
    }

    if received_poll.title.len() < 3 || received_poll.title.len() > 32 || !contains_only(received_poll.title.as_str(), LOWER_ALPHANUMERIC_SYMBOLS_CHARS){
        return Json("Title length must be between 3 and 32 characters long and only contain alphanumeric or these `!? ,;.:-_()[]{}&%$` characters.")
    }

    if received_poll.questions.len()!=0 && (received_poll.questions.len() < 3 || received_poll.questions.len() > 1000){
        return Json("There must be between 3 and 1000 questions.")
    }

    if received_poll.questions.iter().any(|q| (*q).len() < 3 || (*q).len() > 32 || !contains_only((*q).as_str(), LOWER_ALPHA_SPACE_CHARS)){
        return Json("The length of each question must be between 3 and 32, and only contain letters and spaces.")
    }

    match polls.lock() {
        Err(_) => Json("Server error."),
        Ok(mut polls) => {
            if polls.contains_key(&received_poll.name){
                Json("A poll with that name already exists.")
            } else {
                let ReceivedPoll{name, number, title, questions}=received_poll;
                let poll=Poll{number: number, title: title, questions: questions, answers: vec![]};
                polls.insert(name, poll);
                Json("success")
            }
        },
    }
}

fn main() {
    let polls:HashMap<String, Poll>=HashMap::new();
    rocket::ignite()
    .manage(Mutex::new(polls))
    .mount("/", routes![index, files])
    .launch();
}
