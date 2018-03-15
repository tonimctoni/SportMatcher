#![feature(plugin)]
#![feature(custom_derive)]
#![plugin(rocket_codegen)]
extern crate rocket;
// #[macro_use]
extern crate rocket_contrib;
#[macro_use]
extern crate serde_derive;

extern crate rusqlite;
extern crate sha2;
extern crate rand;

mod salter_hasher;
use std::io;
use std::path::{Path, PathBuf};
use std::sync::Mutex;
use rocket::response::NamedFile;
// use rocket::http::RawStr;
use rocket::State;
use rocket_contrib::Json;
// use rocket::response::Redirect;
// use rocket::request::Form;

#[allow(dead_code)]
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

    let mut sh=salter_hasher::SalterHasher::new();
    let (s,h)=sh.salt_and_hash(toni_s_password);
    conn.execute("INSERT INTO Users VALUES(?, ?, ?, ?)", &[&1, &"Toni", &h, &s]).unwrap();
}

#[get("/")]
fn index() -> io::Result<NamedFile> {
    NamedFile::open("frontend/index.html")
}

#[get("/<file..>")]
fn files(file: PathBuf) -> Option<NamedFile> {
    NamedFile::open(Path::new("resources/").join(file)).ok()
}

#[derive(Serialize, Deserialize, Debug)]
struct Credentials {
    nick: String,
    pass: String,
}

#[post("/check_credentials", format = "application/json", data = "<credentials>")]
fn check_credentials(conn: State<Mutex<rusqlite::Connection>>, credentials: Json<Credentials>) -> Json<bool>{
    let Credentials{nick, pass} = credentials.into_inner();
    match conn.lock() {
        Err(_) => Json(false),
        Ok(conn) =>{
            struct PassHashAndSalt(String, String);
            match conn.query_row("SELECT * FROM Users WHERE Nick=?", &[&nick], |row| PassHashAndSalt(row.get(2), row.get(3))){
                Err(_) => Json(false),
                Ok(PassHashAndSalt(pass_hash, salt)) => {
                    Json(salter_hasher::SalterHasher::just_hash(pass.as_str(), salt.as_str()) == pass_hash)
                }
            }
        },
    }
}

// conn: State<Mutex<rusqlite::Connection>>
fn main() {
    let conn=rusqlite::Connection::open("database.sqlite").expect("ERROR: Could not open database");
    rocket::ignite()
    .manage(Mutex::new(conn))
    .mount("/", routes![index, files, check_credentials])
    .launch();
}
