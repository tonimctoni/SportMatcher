extern crate rusqlite;
extern crate sha2;
extern crate rand;

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

fn init_db() {
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
    let (s,h)=sh.salt_and_hash("password");
    conn.execute("INSERT INTO Users VALUES(?, ?, ?, ?)", &[&1, &"Toni", &h, &s]).unwrap();
}



fn main() {
    init_db();
}
