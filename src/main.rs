#![feature(proc_macro_hygiene, decl_macro)]

#[macro_use] extern crate rocket;
extern crate rocket_contrib;
#[macro_use] extern crate serde_derive;


extern crate rand;
use std::sync::Mutex;
use std::io;
use std::path::{Path, PathBuf};
use rocket::response::NamedFile;
use rocket::http::RawStr;
use rocket::response::Redirect;

mod func;
mod data;
mod characters;

#[get("/")]
fn index() -> Redirect {
    Redirect::to("/elm_start_poll")
}

#[get("/elm_start_poll")]
fn index_elm_start_poll() -> io::Result<NamedFile> {
    NamedFile::open("frontend/index.html")
}

#[get("/elm_show_poll_link/<_s>")]
fn index_elm_show_poll_link(_s: &RawStr) -> io::Result<NamedFile> {
    NamedFile::open("frontend/index.html")
}

#[get("/elm_poll/<_s>")]
fn index_elm_poll(_s: &RawStr) -> io::Result<NamedFile> {
    NamedFile::open("frontend/index.html")
}


#[get("/favicon.ico")]
fn icon() -> io::Result<NamedFile> {
    NamedFile::open("static/favicon.ico")
}

#[get("/static/<file..>")]
fn files(file: PathBuf) -> Option<NamedFile> {
    NamedFile::open(Path::new("static/").join(file)).ok()
}

fn main() {
    use func::*;
    let data=data::Data::new();

    rocket::ignite()
    .manage(Mutex::new(data))
    .mount("/", routes![index, icon, files])
    .mount("/", routes![index_elm_start_poll, index_elm_show_poll_link, index_elm_poll])
    .mount("/api/", routes![start_poll, get_poll, fill_poll, fill_free_entry_poll])
    .launch();
}
