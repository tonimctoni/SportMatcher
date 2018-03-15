#![feature(plugin)]
#![feature(custom_derive)]
#![plugin(rocket_codegen)]
extern crate rocket;
#[macro_use]
extern crate rocket_contrib;
// #[macro_use]
// extern crate serde_derive;

extern crate rusqlite;
extern crate sha2;
extern crate rand;

// use std::io;
use std::path::{Path, PathBuf};
use std::sync::Mutex;
use rocket::response::NamedFile;
// use rocket::http::RawStr;
use rocket::State;
// use rocket_contrib::{Json};
use rocket::response::Redirect;
use rocket::request::Form;

use sha2::{Sha512, Digest};
use rand::Rng;
// use rand::distributions::Alphanumeric;

struct SeederHasher {
    rng: rand::ThreadRng
}

impl SeederHasher {
    fn new() -> SeederHasher{
        SeederHasher{rng: rand::thread_rng()}
    }

    fn salt_and_hash(&mut self, password: &str) -> (String, String){
        // let salt=(0..10).map(|_| self.rng.sample(Alphanumeric)).collect();
        let salt=self.rng.gen_ascii_chars().take(10).collect::<String>();

        // Guide says "don't do it this way", but it is not the boss of me.
        let mut hasher=Sha512::new();
        hasher.input(password.as_bytes());
        hasher.input("<$>".as_bytes());
        hasher.input(salt.as_bytes());
        let h=hasher.result().as_slice().iter().fold(String::with_capacity(2*512/8), |mut acc, byte| {acc.push_str(&format!("{:X}", byte));acc});

        (salt, h)
    }

    fn just_hash(password: &str, salt: &str) -> String{
        let mut hasher=Sha512::new();
        hasher.input(password.as_bytes());
        hasher.input("<$>".as_bytes());
        hasher.input(salt.as_bytes());
        hasher.result().as_slice().iter().fold(String::with_capacity(2*512/8), |mut acc, byte| {acc.push_str(&format!("{:X}", byte));acc})
    }
}

fn init_db(toni_s_password: &str) {
    let conn=rusqlite::Connection::open("database.sqlite").expect("ERROR: Could not open database");
    conn.execute("DROP TABLE IF EXISTS Users", &[]).unwrap();
    conn.execute("DROP TABLE IF EXISTS Plugins", &[]).unwrap();
    conn.execute("DROP TABLE IF EXISTS Fills", &[]).unwrap();
    conn.execute("DROP TABLE IF EXISTS Invites", &[]).unwrap();
    conn.execute("DROP TABLE IF EXISTS Reports", &[]).unwrap();

    conn.execute("CREATE TABLE Users(Id INT, Nick TEXT, PassHash TEXT, Salt TEXT)", &[]).unwrap();
    conn.execute("CREATE TABLE Plugins(Id INT, Name TEXT, Json TEXT)", &[]).unwrap();
    conn.execute("CREATE TABLE Fills(UserId INT, PluginId INT, Responses TEXT)", &[]).unwrap();
    conn.execute("CREATE TABLE Invites(FromUserId INT, ToUserId INT, PluginId INT)", &[]).unwrap();
    conn.execute("CREATE TABLE Reports(FromUserId INT, ToUserId INT, PluginId INT, Report TEXT)", &[]).unwrap();

    let mut sh=SeederHasher::new();
    let (s,h)=sh.salt_and_hash(toni_s_password);
    conn.execute("INSERT INTO Users VALUES(?, ?, ?, ?)", &[&1, &"Toni", &h, &s]).unwrap();
}

#[get("/")]
fn index() -> Redirect {
    Redirect::found("/login.html")
}

#[derive(FromForm)]
struct PostLogin {
    nick: String,
    pass: String
}

#[post("/login", data = "<post_login>")]
fn post_login(conn: State<Mutex<rusqlite::Connection>>, post_login: Form<PostLogin>) -> Redirect {
    let post_login: PostLogin = post_login.into_inner();
    match conn.lock() {
        Ok(conn) => {
            conn.query_row("SELECT * FROM Users WHERE Nick='?'", &[&post_login.nick], |row| {
                let a:isize=row.get(0);
                println!("{:?}", a);
                    // , row.get_checked(1), row.get_checked(2), row.get_checked(3)
                });
            Redirect::found("/login.html")
        },
        Err(e) => Redirect::temporary("/internal_error.html"),
    }
    // Redirect::found("/login.html")
}

#[get("/<file..>")]
fn files(file: PathBuf) -> Option<NamedFile> {
    NamedFile::open(Path::new("resources/").join(file)).ok()
}

fn main() {
    let conn=rusqlite::Connection::open("database.sqlite").expect("ERROR: Could not open database");
    rocket::ignite()
    .manage(Mutex::new(conn))
    .mount("/", routes![index, files, post_login])
    .launch();
}
