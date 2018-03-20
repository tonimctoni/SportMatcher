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
use std::fs::File;
use std::sync::Mutex;
use rocket::response::NamedFile;
use std::io::prelude::*;
// use rocket::http::RawStr;
use rocket::State;
use rocket_contrib::Json;
// use rocket::response::Redirect;
// use rocket::request::Form;

const LOWER_ALPHANUMERIC_CHARS: &str = "abcdefghijklmnopqrstuvwxyz0123456789";

fn contains_only(s: &str, chars: &str) -> bool{
    s.chars().all(|c| chars.chars().any(|ac| ac==c))
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
    conn.execute("CREATE TABLE Plugins(Id INT UNIQUE, Name TEXT UNIQUE, Filling TEXT)", &[]).unwrap();
    conn.execute("CREATE TABLE Fills(UserId INT, PluginId INT, Responses TEXT)", &[]).unwrap();
    conn.execute("CREATE TABLE Invites(FromUserId INT, ToUserId INT, PluginId INT)", &[]).unwrap();
    conn.execute("CREATE TABLE Reports(UserId INT, OtherUserId TEXT, PluginId INT, Report TEXT)", &[]).unwrap();

    let mut sh=salter_hasher::SalterHasher::new();
    let (s,h)=sh.salt_and_hash("password");
    conn.execute("INSERT INTO Users VALUES(?, ?, ?, ?)", &[&1, &"toni", &h, &s]).unwrap();


    fn get_dollar_separated_file_content(filepath: &str) -> String{
        let mut f = File::open(filepath).unwrap();
        let mut content=String::new();
        f.read_to_string(&mut content).unwrap();
        content.lines().map(|l| l.into()).collect::<Vec<String>>().join("$")
    }

    conn.execute("INSERT INTO Plugins VALUES(2, \"Sports\", ?)", &[&get_dollar_separated_file_content("plugins/sports.txt")]).unwrap();
    conn.execute("INSERT INTO Plugins VALUES(3, \"Foods\", ?)", &[&get_dollar_separated_file_content("plugins/foods.txt")]).unwrap();
    conn.execute("INSERT INTO Plugins VALUES(4, \"Stuff\", ?)", &[&get_dollar_separated_file_content("plugins/stuff.txt")]).unwrap();
}

fn get_user_id_if_credentials_are_ok(conn: &Mutex<rusqlite::Connection>, nick: &str, pass: &str) -> Option<isize>{
    if !contains_only(&nick, LOWER_ALPHANUMERIC_CHARS){
        return None
    }
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

// fn get_plugin_names_if_credentials_are_ok(conn: &Mutex<rusqlite::Connection>, nick: &str, pass: &str) -> Option<Vec<String>>{
//     if !contains_only(&nick, LOWER_ALPHANUMERIC_CHARS){
//         return None
//     }
//     match conn.lock() {
//         Err(_) => None,
//         Ok(conn) =>{
//             struct PassHashAndSalt(String, String);
//             match conn.query_row("SELECT * FROM Users WHERE Nick=?", &[&nick], |row| PassHashAndSalt(row.get(2), row.get(3))){
//                 Err(_) => None,
//                 Ok(PassHashAndSalt(pass_hash, salt)) => {
//                     if salter_hasher::SalterHasher::just_hash(pass, salt.as_str()) == pass_hash{
//                         match conn.prepare("SELECT Name FROM Plugins"){
//                             Err(_) => None,
//                             Ok(mut stmt) => {
//                                 match stmt.query_map(&[], |row| {row.get(0)}) {
//                                     Err(_) => None,
//                                     Ok(it) => {
//                                         Some(it.filter(|x| x.is_ok()).map(|x| x.unwrap()).collect::<Vec<String>>())
//                                     },
//                                 }
//                             },
//                         }
//                     } else {
//                         None
//                     }
//                 }
//             }
//         },
//     }
// }

fn get_plugin_names_from_db(conn: &Mutex<rusqlite::Connection>) -> Vec<String>{
    match conn.lock() {
        Err(_) => Vec::new(),
        Ok(conn) =>{
            match conn.prepare("SELECT Name FROM Plugins ORDER BY Name"){
                Err(_) => Vec::new(),
                Ok(mut stmt) => {
                    match stmt.query_map(&[], |row| {row.get(0)}) {
                        Err(_) => Vec::new(),
                        Ok(it) => {
                            it.filter(|x| x.is_ok()).map(|x| x.unwrap()).collect::<Vec<String>>()
                        },
                    }
                },
            }
        },
    }
}

fn get_plugin_filling_from_db(conn: &Mutex<rusqlite::Connection>, name: &str) -> Vec<String>{
    match conn.lock() {
        Err(_) => Vec::new(),
        Ok(conn) =>{
            struct AString(String);
            match conn.query_row("SELECT Filling FROM Plugins WHERE Name=?", &[&name], |row| AString(row.get(0))){
                Err(_) => Vec::new(),
                Ok(AString(filling)) => {
                    let mut filling=filling.split("$").map(|x| x.into()).collect::<Vec<String>>();
                    filling.sort_unstable();
                    filling
                }
            }
        },
    }
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
    let Credentials{mut nick, pass} = credentials.into_inner();
    nick.make_ascii_lowercase();
    Json(get_user_id_if_credentials_are_ok(&conn, nick.as_str(), pass.as_str()).is_some())
}

#[get("/get_plugin_names")]
fn get_plugin_names(conn: State<Mutex<rusqlite::Connection>>) ->Json<Vec<String>>{
    Json(get_plugin_names_from_db(&conn))
}

#[post("/get_plugin_filling", format = "application/json", data = "<plugin_name>")]
fn get_plugin_filling(conn: State<Mutex<rusqlite::Connection>>, plugin_name: Json<String>) -> Json<Vec<String>>{
    let plugin_name = plugin_name.into_inner();
    Json(get_plugin_filling_from_db(&conn, plugin_name.as_str()))
}

fn main() {
    init_db();
    let conn=rusqlite::Connection::open("database.sqlite").expect("ERROR: Could not open database");
    rocket::ignite()
    .manage(Mutex::new(conn))
    .mount("/", routes![index, files, check_credentials, get_plugin_names, get_plugin_filling])
    .launch();
}
