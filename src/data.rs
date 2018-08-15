use std::collections::HashMap;
use rand::rngs::{StdRng, EntropyRng};
use rand::SeedableRng;
use rand::RngCore;



pub struct Poll {
    pub number: isize,
    pub title: String,
    pub questions: Vec<String>,
    pub answers: Vec<(String, Vec<String>)>,
}

pub struct Data {
    polls: HashMap<String, Poll>, // Poll id -> Poll
    rng: StdRng,
}

impl Data {
    pub fn new() -> Data{
        Data{
            polls: HashMap::new(),
            rng: StdRng::from_rng(EntropyRng::new()).unwrap(),
        }
    }

    pub fn add_poll(&mut self, poll: Poll) -> String{
        let id=format!("{:X}", self.rng.next_u64());
        self.polls.insert(id.clone(), poll); //Some polls might get overwritten, but that is unlikely, so it is ok.
        id
    }

    pub fn get_poll(&self, poll_id: &String) -> Option<&Poll>{
        self.polls.get(poll_id)
    }

    pub fn get_poll_mut(&mut self, poll_id: &String) -> Option<&mut Poll>{
        self.polls.get_mut(poll_id)
    }
}