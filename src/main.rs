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

fn contains_lower_alphanumeric_only(s: &str) -> bool{
    const ALLOWED_CHARS: &str = "abcdefghijklmnopqrstuvwxyz0123456789";
    s.chars().all(|c| ALLOWED_CHARS.chars().any(|ac| ac==c))
}

#[allow(dead_code)]
fn init_db() {
    let conn=rusqlite::Connection::open("database.sqlite").expect("ERROR: Could not open database");
    conn.execute("DROP TABLE IF EXISTS Users", &[]).unwrap();
    conn.execute("DROP TABLE IF EXISTS Plugins", &[]).unwrap();
    conn.execute("DROP TABLE IF EXISTS Fills", &[]).unwrap();
    conn.execute("DROP TABLE IF EXISTS Invites", &[]).unwrap();
    conn.execute("DROP TABLE IF EXISTS Reports", &[]).unwrap();

    conn.execute("CREATE TABLE Users(Id INT UNIQUE, Nick TEXT UNIQUE, PassHash TEXT, Salt TEXT)", &[]).unwrap();
    conn.execute("CREATE TABLE Plugins(Id INT UNIQUE, Name TEXT UNIQUE, Filename TEXT)", &[]).unwrap();
    conn.execute("CREATE TABLE Fills(UserId INT, PluginId INT, Responses TEXT)", &[]).unwrap();
    conn.execute("CREATE TABLE Invites(FromUserId INT, ToUserId INT, PluginId INT)", &[]).unwrap();
    conn.execute("CREATE TABLE Reports(UserId INT, OtherUserName TEXT, PluginId INT, Report TEXT)", &[]).unwrap();

    let mut sh=salter_hasher::SalterHasher::new();
    let (s,h)=sh.salt_and_hash("password");
    conn.execute("INSERT INTO Users VALUES(?, ?, ?, ?)", &[&1, &"toni", &h, &s]).unwrap();

    conn.execute("INSERT INTO Plugins VALUES(2, \"Sports\", \"sports.txt\")", &[]).unwrap();
    conn.execute("INSERT INTO Plugins VALUES(3, \"Foods\", \"foods.txt\")", &[]).unwrap();
}

#[get("/")]
fn index() -> io::Result<NamedFile> {
    NamedFile::open("frontend/index.html")
}

#[get("/<file..>")]
fn files(file: PathBuf) -> Option<NamedFile> {
    NamedFile::open(Path::new("resources/").join(file)).ok()
}

fn get_user_id_if_credentials_are_ok(conn: &Mutex<rusqlite::Connection>, nick: &str, pass: &str) -> Option<isize>{
    match conn.lock() {
        Err(_) => None,
        Ok(conn) =>{
            struct IdPassHashAndSalt(isize, String, String);
            match conn.query_row("SELECT * FROM Users WHERE Nick=?", &[&nick], |row| IdPassHashAndSalt(row.get(0), row.get(2), row.get(3))){
                Err(_) => None,
                Ok(IdPassHashAndSalt(id, pass_hash, salt)) => {
                    if salter_hasher::SalterHasher::just_hash(pass, salt.as_str()) == pass_hash{
                        Some(id)
                    } else {
                        None
                    }
                }
            }
        },
    }
}

#[derive(Serialize, Deserialize, Debug)]
struct Credentials {
    nick: String,
    pass: String,
}

#[post("/check_credentials", format = "application/json", data = "<credentials>")]
fn check_credentials(conn: State<Mutex<rusqlite::Connection>>, credentials: Json<Credentials>) -> Json<bool>{
    let Credentials{mut nick, pass} = credentials.into_inner();
    nick.make_ascii_lowercase();
    if !contains_lower_alphanumeric_only(nick.as_str()){
        return Json(false)
    }
    Json(get_user_id_if_credentials_are_ok(&conn, nick.as_str(), pass.as_str()).is_some())
    // match conn.lock() {
    //     Err(_) => Json(false),
    //     Ok(conn) =>{
    //         struct PassHashAndSalt(String, String);
    //         match conn.query_row("SELECT * FROM Users WHERE Nick=?", &[&nick], |row| PassHashAndSalt(row.get(2), row.get(3))){
    //             Err(_) => Json(false),
    //             Ok(PassHashAndSalt(pass_hash, salt)) => {
    //                 Json(salter_hasher::SalterHasher::just_hash(pass.as_str(), salt.as_str()) == pass_hash)
    //             }
    //         }
    //     },
    // }
}

// #[post("/get_plugin_names", format = "application/json")]
// fn get_plugin_names

fn main() {
    init_db();
    let conn=rusqlite::Connection::open("database.sqlite").expect("ERROR: Could not open database");
    rocket::ignite()
    .manage(Mutex::new(conn))
    .mount("/", routes![index, files, check_credentials])
    .launch();
}
