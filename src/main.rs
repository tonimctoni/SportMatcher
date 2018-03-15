extern crate rusqlite;

// use rusqlite;

fn main() {
    rusqlite::Connection::open("database.db");
    println!("Hello, world!");
}


// Report can be a String of ABCs (or YON), standing for Yay, Open, Nope