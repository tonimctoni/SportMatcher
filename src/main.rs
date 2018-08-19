#![feature(plugin)]
#![feature(custom_derive)]
#![plugin(rocket_codegen)]
extern crate rocket;
extern crate rocket_contrib;
#[macro_use]
extern crate serde_derive;
#[cfg(test)]
#[macro_use]
extern crate serde_json;
extern crate rand;
use std::sync::Mutex;
use std::io;
use std::path::{Path, PathBuf};
use rocket::response::NamedFile;
use rocket::response::Redirect;

mod func;
mod data;
mod characters;

// STATIC

#[get("/")]
fn index() -> Redirect {
    Redirect::to("/elm/start_poll")
}

#[get("/favicon.ico")]
fn icon() -> io::Result<NamedFile> {
    NamedFile::open("static/favicon.ico")
}

#[get("/static/<file..>")]
fn files(file: PathBuf) -> Option<NamedFile> {
    NamedFile::open(Path::new("static/").join(file)).ok()
}

// ELM

#[get("/start_poll")]
fn elm_start_poll() -> io::Result<NamedFile> {
    NamedFile::open("frontend/start_poll/index.html")
}

#[get("/fill_poll")]
fn elm_fill_poll() -> io::Result<NamedFile> {
    NamedFile::open("frontend/fill_poll/index.html")
}

#[get("/see_poll")]
fn elm_see_poll() -> io::Result<NamedFile> {
    NamedFile::open("frontend/see_poll/index.html")
}

fn main() {
    use func::*;
    let data=data::Data::new();

    rocket::ignite()
    .manage(Mutex::new(data))
    .mount("/", routes![index, icon, files])
    .mount("/elm/", routes![elm_start_poll, elm_fill_poll, elm_see_poll])
    .mount("/api/", routes![start_poll, get_poll, fill_poll, fill_free_entry_poll, get_poll_results])
    .launch();
}
